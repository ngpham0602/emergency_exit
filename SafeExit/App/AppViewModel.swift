import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var buildingPackage: BuildingPackage?
    @Published private(set) var routeResult: RouteResult?
    @Published private(set) var routeFailureMessage: String?
    @Published var selectedStartNodeID: String?
    @Published var accessibilityMode = false {
        didSet { recomputeRoute() }
    }
    @Published var prefersAudioGuidance = false

    // Emergency alert state
    @Published var activeEmergencyAlert: EmergencyAlert?
    @Published var showEmergencyAlert = false
    @Published var shouldNavigateToMap = false

    // Reported hazard state (synced across devices)
    @Published var hasReportedHazards = false

    let container: AppContainer
    private var alertListener: ListenerRegistration?
    private var hazardListener: ListenerRegistration?
    private var lastNotifiedAlertID: String?

    init(container: AppContainer) {
        self.container = container
        loadBuilding()
    }

    deinit {
        alertListener?.remove()
        hazardListener?.remove()
    }

    var roomNodes: [Node] {
        buildingPackage?.nodes.filter { $0.type == .room } ?? []
    }

    var currentStartNode: Node? {
        guard let selectedStartNodeID, let buildingPackage else { return nil }
        return buildingPackage.node(id: selectedStartNodeID)
    }

    var activeHazards: [HazardEvent] {
        container.hazardStateManager.activeHazards
    }

    func loadBuilding() {
        do {
            let loaded = try container.buildingRepository.loadSamplePackage()
            buildingPackage = loaded
            container.hazardStateManager.register(hazards: loaded.hazardTemplates)
            if selectedStartNodeID == nil {
                selectedStartNodeID = loaded.defaultStartNodeID ?? loaded.nodes.first(where: { $0.type == .room })?.id
            }
            recomputeRoute()
        } catch {
            routeFailureMessage = "Unable to load building package."
        }
    }

    func selectStartNode(_ nodeID: String) {
        selectedStartNodeID = nodeID
        recomputeRoute()
    }

    func toggleHazard(_ hazardID: String, enabled: Bool) {
        container.hazardStateManager.setHazardState(hazardID: hazardID, isActive: enabled)
        objectWillChange.send()
        recomputeRoute()

        // Sync to Firestore so all devices see it
        if enabled {
            let title = container.hazardStateManager.activeHazards
                .first(where: { $0.id == hazardID })?.title ?? "Hazard"
            Task {
                try? await FirestoreService.shared.reportActiveHazard(
                    hazardID: hazardID, title: title, type: "reported"
                )
            }
        }
    }

    func resetHazards() {
        container.hazardStateManager.reset()
        objectWillChange.send()
        recomputeRoute()
    }

    func placeAdHocHazard(nodeID: String, severity: HazardSeverity) {
        guard let node = buildingPackage?.node(id: nodeID) else { return }
        container.hazardStateManager.addAdHocHazard(nodeID: nodeID, nodeName: node.name, severity: severity)
        recomputeRoute()
    }

    func clearAdHocHazards(nodeID: String) {
        container.hazardStateManager.removeAdHocHazards(nodeID: nodeID)
        recomputeRoute()
    }

    func nodeHasHazard(_ nodeID: String) -> Bool {
        container.hazardStateManager.hasActiveHazard(nodeID: nodeID)
    }

    func recomputeRoute() {
        guard let buildingPackage, let selectedStartNodeID else {
            routeResult = nil
            return
        }

        do {
            let result = try container.routingEngine.computeRoute(
                in: buildingPackage,
                startNodeID: selectedStartNodeID,
                activeHazards: container.hazardStateManager.activeHazards,
                accessibilityMode: accessibilityMode
            )
            routeResult = result
            routeFailureMessage = nil
        } catch {
            routeResult = nil
            routeFailureMessage = error.localizedDescription
        }
    }

    // MARK: - Emergency alerts

    func startListeningForEmergencyAlerts() {
        alertListener?.remove()
        alertListener = FirestoreService.shared.listenToEmergencyAlerts { [weak self] alerts in
            Task { @MainActor in
                guard let self else { return }

                if let latest = alerts.sorted(by: { $0.timestamp > $1.timestamp }).first {
                    if self.lastNotifiedAlertID != latest.id {
                        self.lastNotifiedAlertID = latest.id
                        self.activeEmergencyAlert = latest
                        self.showEmergencyAlert = true
                        EmergencyNotificationManager.shared.fireEmergencyNotification(type: latest.type)
                    }
                } else {
                    // Firestore returned zero active alerts — clear everything
                    self.activeEmergencyAlert = nil
                    self.showEmergencyAlert = false
                    self.lastNotifiedAlertID = nil
                }
            }
        }
    }

    func onEmergencyAlertSent(_ alert: EmergencyAlert) {
        activeEmergencyAlert = alert
        lastNotifiedAlertID = alert.id
    }

    func navigateToMap() {
        shouldNavigateToMap = true
    }

    // MARK: - Reported hazards (synced across devices)

    func startListeningForReportedHazards() {
        hazardListener?.remove()
        hazardListener = FirestoreService.shared.listenToReportedHazards { [weak self] hazards in
            Task { @MainActor in
                guard let self else { return }
                let hadHazards = self.hasReportedHazards
                self.hasReportedHazards = !hazards.isEmpty

                // On employee devices: apply hazards from Firestore to local state
                for h in hazards {
                    if let id = h["id"] as? String {
                        self.container.hazardStateManager.setHazardState(hazardID: id, isActive: true)
                    }
                }

                // If hazards were cleared (security stopped them), reset local state
                if hadHazards && hazards.isEmpty {
                    self.container.hazardStateManager.reset()
                }

                self.objectWillChange.send()
                self.recomputeRoute()
            }
        }
    }

    /// Security stops all reported hazards — clears Firestore + local state on all devices.
    func stopAllHazards() {
        // Kill listener to prevent re-trigger
        hazardListener?.remove()
        hazardListener = nil

        // Clear local state
        container.hazardStateManager.reset()
        hasReportedHazards = false
        objectWillChange.send()
        recomputeRoute()

        // Delete from Firestore, then restart listener
        Task {
            try? await FirestoreService.shared.deleteAllReportedHazards()
            self.startListeningForReportedHazards()
        }
    }

    /// Security officer stops the alert.
    func stopEmergencyAlert() {
        guard activeEmergencyAlert != nil else { return }

        // 1. Kill the listener so it cannot re-trigger anything
        alertListener?.remove()
        alertListener = nil

        // 2. Clear all local state
        activeEmergencyAlert = nil
        showEmergencyAlert = false
        lastNotifiedAlertID = nil

        // 3. Remove all local notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        // 4. Delete ALL alert documents from Firestore (including stale ones),
        //    wait for the delete to complete, then restart listener
        Task {
            try? await FirestoreService.shared.deleteAllActiveEmergencyAlerts()
            // Now restart — Firestore has zero documents, listener returns empty
            self.startListeningForEmergencyAlerts()
        }
    }
}
