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
}
