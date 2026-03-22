import Foundation

// MARK: - Emergency type

enum EmergencyType: String, Codable, CaseIterable, Identifiable {
    case fire          = "fire"
    case activeShooter = "active_shooter"
    case earthquake    = "earthquake"
    case other         = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fire:          return "Fire"
        case .activeShooter: return "Active Shooter"
        case .earthquake:    return "Earthquake"
        case .other:         return "Other"
        }
    }

    var icon: String {
        switch self {
        case .fire:          return "flame.fill"
        case .activeShooter: return "figure.run"
        case .earthquake:    return "waveform.path.ecg"
        case .other:         return "exclamationmark.triangle.fill"
        }
    }

    var shortInstruction: String {
        switch self {
        case .fire:          return "Evacuate now. Find the nearest exit immediately."
        case .activeShooter: return "Run, Hide. Get to safety now."
        case .earthquake:    return "Drop, Cover, Hold On. Move to open area when safe."
        case .other:         return "Emergency alert. Find the nearest exit now."
        }
    }

    var notificationTitle: String {
        switch self {
        case .fire:          return "FIRE EMERGENCY"
        case .activeShooter: return "ACTIVE SHOOTER"
        case .earthquake:    return "EARTHQUAKE ALERT"
        case .other:         return "EMERGENCY ALERT"
        }
    }
}

// MARK: - Emergency alert (Firestore document)

struct EmergencyAlert: Codable, Identifiable {
    var id: String
    var type: EmergencyType
    var message: String
    var sentBy: String          // uid of security officer
    var sentByName: String
    var timestamp: Date
    var isActive: Bool

    var displayTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
