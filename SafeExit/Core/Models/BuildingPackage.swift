import Foundation

struct BuildingPackage: Codable {
    let metadata: BuildingMetadata
    let floors: [Floor]
    let nodes: [Node]
    let edges: [Edge]
    let exits: [BuildingExit]
    let refugePoints: [RefugePoint]
    let hazardTemplates: [HazardEvent]
    let defaultStartNodeID: String?

    func node(id: String) -> Node? {
        nodes.first(where: { $0.id == id })
    }
}

struct BuildingMetadata: Codable {
    let id: String
    let name: String
    let version: String
}

struct Floor: Codable, Identifiable {
    let id: String
    let name: String
    let level: Int
}

struct Node: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: NodeType
    let floor: String
    let coordinates: Coordinates
}

struct Coordinates: Codable, Hashable {
    let x: Double
    let y: Double
}

enum NodeType: String, Codable {
    case room
    case intersection
    case stairwell
    case lift
    case exit
    case refugePoint
}

struct Edge: Codable, Identifiable, Hashable {
    let id: String
    let fromNodeID: String
    let toNodeID: String
    let distance: Double
    let edgeType: EdgeType
    let accessibilityFlags: AccessibilityFlags
}

enum EdgeType: String, Codable {
    case corridor
    case stair
    case lift
    case doorway
}

struct AccessibilityFlags: Codable, Hashable {
    let wheelchairAccessible: Bool
}

struct BuildingExit: Codable, Identifiable, Hashable {
    let id: String
    let nodeID: String
    let type: ExitType
    let status: ExitStatus
}

enum ExitType: String, Codable {
    case primary
    case secondary
}

enum ExitStatus: String, Codable {
    case available
    case unavailable
}

struct RefugePoint: Codable, Identifiable, Hashable {
    let id: String
    let nodeID: String
    let capacityNote: String
    let instructions: String
}
