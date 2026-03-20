import Foundation
import SwiftUI

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

    let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        loadBuilding()
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
        recomputeRoute()
    }

    func resetHazards() {
        container.hazardStateManager.reset()
        recomputeRoute()
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
}
