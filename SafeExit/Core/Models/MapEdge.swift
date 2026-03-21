import Foundation
import FirebaseFirestore

struct MapEdge: Codable, Identifiable {
    @DocumentID var id: String?
    var fromNodeId: String        // one end of the walkable path
    var toNodeId: String          // other end of the walkable path
    var distanceMeters: Double    // estimated real walking distance
    var isBlocked: Bool           // true = confirmed hazard, don't use this path
    var hazardPenalty: Double     // 0 = clear | high number = avoid | infinity = blocked
}
