import Foundation
import SwiftUI

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

enum HazardSeverity: String, Codable, CaseIterable {
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

    var displayTitle: String {
        switch self {
        case .blocked:      return "Blocked"
        case .highRisk:     return "High Risk"
        case .inaccessible: return "Inaccessible"
        }
    }

    var detailText: String {
        switch self {
        case .blocked:      return "Route treats this location as impassable"
        case .highRisk:     return "Route avoids if possible, uses with penalty"
        case .inaccessible: return "Blocked for wheelchair / accessibility users"
        }
    }

    var icon: String {
        switch self {
        case .blocked:      return "xmark.octagon.fill"
        case .highRisk:     return "exclamationmark.triangle.fill"
        case .inaccessible: return "figure.roll"
        }
    }

    var accentColor: Color {
        switch self {
        case .blocked:      return Color(red: 0.90, green: 0.25, blue: 0.25)
        case .highRisk:     return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .inaccessible: return Color(red: 0.90, green: 0.25, blue: 0.25)
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
