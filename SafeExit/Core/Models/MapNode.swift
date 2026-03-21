import Foundation
import FirebaseFirestore

struct MapNode: Codable, Identifiable {
    @DocumentID var id: String?
    var floorId: String
    var type: String              // "exit" | "stairwell" | "elevator" | "corridor"
    var label: String             // "Emergency Exit B" "Stair 2"
    var xPercent: Double          // 0.0 = left edge, 1.0 = right edge
    var yPercent: Double          // 0.0 = top edge,  1.0 = bottom edge
    var isAccessible: Bool        // wheelchair accessible?
    var isExit: Bool              // does this lead outside the building?
}
