import Foundation
import FirebaseFirestore

struct Building: Codable, Identifiable {
    @DocumentID var id: String?   // auto-set by Firestore
    var name: String
    var address: String
    var type: String              // "mall" | "office" | "entertainment"
    var verified: Bool
    var uploadCount: Int
    var confidenceScore: Double   // 0.0 to 1.0
}
