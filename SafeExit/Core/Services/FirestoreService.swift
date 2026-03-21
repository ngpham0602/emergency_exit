import Foundation
import FirebaseFirestore

// Singleton — one shared instance used everywhere in SafeExit
// Usage anywhere in the app: FirestoreService.shared.fetchBuildings()

class FirestoreService {

    static let shared = FirestoreService()
    private lazy var db = Firestore.firestore()
    private init() {}


    // —— BUILDINGS ————————————————————————————————————————————————————————

    func fetchBuildings() async throws -> [Building] {
        let snapshot = try await db.collection("buildings").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Building.self) }
    }

    func searchBuildings(query: String) async throws -> [Building] {
        let snapshot = try await db.collection("buildings")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThan: query + "\u{f8ff}")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Building.self) }
    }

    func fetchBuilding(id: String) async throws -> Building {
        let doc = try await db.collection("buildings").document(id).getDocument()
        return try doc.data(as: Building.self)
    }

    func createBuilding(_ building: Building) async throws -> String {
        let ref = try db.collection("buildings").addDocument(from: building)
        return ref.documentID
    }


    // —— FLOORS ———————————————————————————————————————————————————————————

    func fetchFloors(buildingId: String) async throws -> [Floor] {
        let snapshot = try await db
            .collection("buildings").document(buildingId)
            .collection("floors").order(by: "floorNumber")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Floor.self) }
    }

    func createFloor(_ floor: Floor, buildingId: String) async throws -> String {
        let ref = try db
            .collection("buildings").document(buildingId)
            .collection("floors").addDocument(from: floor)
        return ref.documentID
    }

    func updateFloorAnalysisStatus(
        floorId: String,
        buildingId: String,
        status: String
    ) async throws {
        try await db
            .collection("buildings").document(buildingId)
            .collection("floors").document(floorId)
            .updateData(["analysisStatus": status])
    }


    // —— NODES ————————————————————————————————————————————————————————————

    func fetchNodes(floorId: String, buildingId: String) async throws -> [MapNode] {
        let snapshot = try await db
            .collection("buildings").document(buildingId)
            .collection("floors").document(floorId)
            .collection("nodes").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: MapNode.self) }
    }

    func saveNodes(_ nodes: [MapNode], floorId: String, buildingId: String) async throws {
        let batch = db.batch()
        for node in nodes {
            let ref = db
                .collection("buildings").document(buildingId)
                .collection("floors").document(floorId)
                .collection("nodes").document()
            try batch.setData(from: node, forDocument: ref)
        }
        try await batch.commit()
    }


    // —— EDGES ————————————————————————————————————————————————————————————

    func fetchEdges(floorId: String, buildingId: String) async throws -> [MapEdge] {
        let snapshot = try await db
            .collection("buildings").document(buildingId)
            .collection("floors").document(floorId)
            .collection("edges").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: MapEdge.self) }
    }

    func saveEdges(_ edges: [MapEdge], floorId: String, buildingId: String) async throws {
        let batch = db.batch()
        for edge in edges {
            let ref = db
                .collection("buildings").document(buildingId)
                .collection("floors").document(floorId)
                .collection("edges").document()
            try batch.setData(from: edge, forDocument: ref)
        }
        try await batch.commit()
    }


    // —— HAZARDS ——————————————————————————————————————————————————————————

    func reportHazard(_ hazard: Hazard) async throws {
        try db.collection("hazards").addDocument(from: hazard)
    }

    func fetchActiveHazards(floorId: String) async throws -> [Hazard] {
        let snapshot = try await db.collection("hazards")
            .whereField("floorId", isEqualTo: floorId)
            .whereField("expiresAt", isGreaterThan: Date())
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Hazard.self) }
    }

    // Real-time listener — fires immediately and every time hazards change
    // Save the returned ListenerRegistration and call .remove() when view disappears
    func listenToHazards(
        floorId: String,
        onChange: @escaping ([Hazard]) -> Void
    ) -> ListenerRegistration {
        return db.collection("hazards")
            .whereField("floorId", isEqualTo: floorId)
            .addSnapshotListener { snapshot, _ in
                let hazards = snapshot?.documents
                    .compactMap { try? $0.data(as: Hazard.self) } ?? []
                onChange(hazards)
            }
    }
}
