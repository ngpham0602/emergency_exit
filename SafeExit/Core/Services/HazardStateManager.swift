import Foundation

final class HazardStateManager {
    private(set) var activeHazards: [HazardEvent] = []
    private var knownHazards: [String: HazardEvent] = [:]

    func register(hazards: [HazardEvent]) {
        for hazard in hazards {
            knownHazards[hazard.id] = hazard
        }
    }

    func setHazardState(hazardID: String, isActive: Bool) {
        guard let hazard = knownHazards[hazardID] else { return }

        if isActive {
            if !activeHazards.contains(hazard) {
                activeHazards.append(hazard)
            }
        } else {
            activeHazards.removeAll { $0.id == hazardID }
        }
    }

    func reset() {
        activeHazards.removeAll()
    }

    // Add a user-tapped ad-hoc hazard. Replaces any existing ad-hoc hazard on the same node.
    func addAdHocHazard(nodeID: String, nodeName: String, severity: HazardSeverity) {
        activeHazards.removeAll { $0.id.hasPrefix("adhoc-\(nodeID)-") }
        let hazard = HazardEvent(
            id: "adhoc-\(nodeID)-\(UUID().uuidString)",
            title: "\(severity.displayTitle) – \(nodeName)",
            targetNodeIDs: [nodeID],
            targetEdgeIDs: [],
            severity: severity,
            status: .reported,
            confidence: .high,
            timestamp: Date()
        )
        activeHazards.append(hazard)
    }

    // Remove all ad-hoc hazards placed on a specific node.
    func removeAdHocHazards(nodeID: String) {
        activeHazards.removeAll { $0.id.hasPrefix("adhoc-\(nodeID)-") }
    }

    func hasActiveHazard(nodeID: String) -> Bool {
        activeHazards.contains { $0.targetNodeIDs.contains(nodeID) }
    }
}
