import Foundation

struct RouteResult: Equatable {
    let destinationNode: Node
    let destinationKind: DestinationKind
    let path: [Node]
    let totalDistance: Double
    let instructions: [RouteInstruction]
}

enum DestinationKind: Equatable {
    case exit
    case refugePoint
}

struct RouteInstruction: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}
