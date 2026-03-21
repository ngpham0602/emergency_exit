import Foundation
import FirebaseFirestore

struct Hazard: Codable, Identifiable {
    @DocumentID var id: String?
    var buildingId: String
    var floorId: String
    var type: String              // "fire" | "smoke" | "debris" | "other"
    var xPercent: Double          // position on map, same system as MapNode
    var yPercent: Double
    var confidence: Double        // 0.0 = unverified → 1.0 = fully confirmed
    var confirmations: Int        // how many users confirmed this
    var reportedBy: String        // device ID — not the user's real name
    var timestamp: Date
    var expiresAt: Date           // auto-expire after 10 minutes
}
