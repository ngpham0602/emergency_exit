import Foundation

struct HazardEvent: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let targetNodeIDs: [String]
    let targetEdgeIDs: [String]
    let severity: HazardSeverity
    let status: HazardStatus
    let confidence: HazardConfidence
    let timestamp: Date
}

enum HazardSeverity: String, Codable {
    case blocked
    case highRisk
    case inaccessible

    var multiplier: Double {
        switch self {
        case .blocked:
            return .infinity
        case .highRisk:
            return 5.0
        case .inaccessible:
            return .infinity
        }
    }
}

enum HazardStatus: String, Codable {
    case reported
    case verified
    case simulated
}

enum HazardConfidence: String, Codable {
    case low
    case medium
    case high
}
