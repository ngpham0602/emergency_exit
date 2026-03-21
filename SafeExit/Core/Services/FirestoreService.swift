import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

// Singleton — one shared instance used everywhere in SafeExit
// Usage anywhere in the app: FirestoreService.shared.fetchBuildings()

// Firestore document for a floor plan library entry.
// imageURL points to the full-resolution JPEG in Firebase Storage (floorPlans/{id}.jpg).
struct FloorPlanRecord: Codable {
    var id:           String
    var name:         String
    var floorLabel:   String
    var status:       String   // raw value of FloorPlanStatus
    var lastModified: Date
    var imageURL:     String?  // Firebase Storage download URL
}

class FirestoreService {

    static let shared = FirestoreService()
    private let db      = Firestore.firestore()
    private let storage = Storage.storage()
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


    // —— MAP EDITOR ———————————————————————————————————————————————————————

    private func nodeRef(mapID: String, nodeID: String) -> DocumentReference {
        db.collection("mapEditor").document(mapID).collection("nodes").document(nodeID)
    }
    private func edgeRef(mapID: String, edgeID: String) -> DocumentReference {
        db.collection("mapEditor").document(mapID).collection("edges").document(edgeID)
    }

    func fetchCustomNodes(mapID: String) async throws -> [CustomNode] {
        let snap = try await db.collection("mapEditor").document(mapID)
            .collection("nodes").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: CustomNode.self) }
    }

    func setCustomNode(_ node: CustomNode, mapID: String) async throws {
        try nodeRef(mapID: mapID, nodeID: node.id).setData(from: node)
    }

    func deleteCustomNode(nodeID: String, mapID: String) async throws {
        try await nodeRef(mapID: mapID, nodeID: nodeID).delete()
    }

    func fetchCustomEdges(mapID: String) async throws -> [CustomEdge] {
        let snap = try await db.collection("mapEditor").document(mapID)
            .collection("edges").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: CustomEdge.self) }
    }

    func setCustomEdge(_ edge: CustomEdge, mapID: String) async throws {
        try edgeRef(mapID: mapID, edgeID: edge.id).setData(from: edge)
    }

    func deleteCustomEdge(edgeID: String, mapID: String) async throws {
        try await edgeRef(mapID: mapID, edgeID: edgeID).delete()
    }

    func clearCustomGraph(mapID: String) async throws {
        let nodeSnap = try await db.collection("mapEditor").document(mapID)
            .collection("nodes").getDocuments()
        let edgeSnap = try await db.collection("mapEditor").document(mapID)
            .collection("edges").getDocuments()
        let batch = db.batch()
        nodeSnap.documents.forEach { batch.deleteDocument($0.reference) }
        edgeSnap.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }

    // —— FLOOR PLAN LIBRARY ———————————————————————————————————————————————
    // Metadata in Firestore:  floorPlans/{id}
    // Full image in Storage:  floorPlans/{id}.jpg

    func fetchFloorPlanRecords() async throws -> [FloorPlanRecord] {
        let snap = try await db.collection("floorPlans").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: FloorPlanRecord.self) }
    }

    func saveFloorPlanRecord(_ record: FloorPlanRecord) async throws {
        try db.collection("floorPlans").document(record.id).setData(from: record)
    }

    func deleteFloorPlanRecord(id: String) async throws {
        try await db.collection("floorPlans").document(id).delete()
    }

    func updateFloorPlanFields(id: String, fields: [String: Any]) async throws {
        try await db.collection("floorPlans").document(id).updateData(fields)
    }

    /// Upload a floor plan image to Firebase Storage and return its download URL string.
    func uploadFloorPlanImage(_ image: UIImage, id: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "FloorPlan", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not encode image as JPEG"])
        }
        let ref = storage.reference().child("floorPlans/\(id).jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    /// Download a floor plan image from a Firebase Storage URL.
    func downloadFloorPlanImage(url: String) async throws -> UIImage {
        guard let parsedURL = URL(string: url) else {
            throw NSError(domain: "FloorPlan", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid Storage URL"])
        }
        let (data, _) = try await URLSession.shared.data(from: parsedURL)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "FloorPlan", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not decode downloaded image"])
        }
        return image
    }

    /// Delete a floor plan image from Firebase Storage.
    func deleteFloorPlanImage(id: String) async throws {
        try await storage.reference().child("floorPlans/\(id).jpg").delete()
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


    // —— EMERGENCY ALERTS ———————————————————————————————————————————————

    /// Security officer broadcasts an emergency alert to all employees.
    func sendEmergencyAlert(_ alert: EmergencyAlert) async throws {
        try db.collection("emergencyAlerts").document(alert.id).setData(from: alert)
    }

    /// Delete a single emergency alert document.
    func deactivateEmergencyAlert(id: String) async throws {
        try await db.collection("emergencyAlerts").document(id).delete()
    }

    /// Delete ALL active emergency alert documents.
    /// This ensures no stale alerts from previous tests remain.
    func deleteAllActiveEmergencyAlerts() async throws {
        let snapshot = try await db.collection("emergencyAlerts").getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }


    // —— REPORTED HAZARDS (synced across devices) ——————————————————————————

    /// Save a reported hazard so all devices can see it.
    func reportActiveHazard(hazardID: String, title: String, type: String) async throws {
        try await db.collection("activeHazards").document(hazardID).setData([
            "id": hazardID,
            "title": title,
            "type": type,
            "timestamp": FieldValue.serverTimestamp(),
            "isActive": true
        ])
    }

    /// Delete all active reported hazards (security stops them).
    func deleteAllReportedHazards() async throws {
        let snapshot = try await db.collection("activeHazards").getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }

    /// Real-time listener for reported hazards across devices.
    func listenToReportedHazards(
        onChange: @escaping ([[String: Any]]) -> Void
    ) -> ListenerRegistration {
        return db.collection("activeHazards")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snapshot, _ in
                let hazards = snapshot?.documents.map { $0.data() } ?? []
                onChange(hazards)
            }
    }

    /// Real-time listener for active emergency alerts.
    func listenToEmergencyAlerts(
        onChange: @escaping ([EmergencyAlert]) -> Void
    ) -> ListenerRegistration {
        return db.collection("emergencyAlerts")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snapshot, _ in
                let alerts = snapshot?.documents
                    .compactMap { try? $0.data(as: EmergencyAlert.self) } ?? []
                onChange(alerts)
            }
    }
}
