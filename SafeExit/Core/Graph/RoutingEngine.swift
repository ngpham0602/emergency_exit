import Foundation

enum RoutingError: LocalizedError {
    case invalidStartNode
    case noRouteAvailable

    var errorDescription: String? {
        switch self {
        case .invalidStartNode:
            return "The selected room could not be found."
        case .noRouteAvailable:
            return "No safe route is currently available."
        }
    }
}

struct RoutingEngine {
    func computeRoute(
        in building: BuildingPackage,
        startNodeID: String,
        activeHazards: [HazardEvent],
        accessibilityMode: Bool
    ) throws -> RouteResult {
        guard building.node(id: startNodeID) != nil else {
            throw RoutingError.invalidStartNode
        }

        if let exitRoute = bestRoute(
            in: building,
            startNodeID: startNodeID,
            destinations: building.exits
                .filter { $0.status == .available }
                .compactMap { building.node(id: $0.nodeID) },
            activeHazards: activeHazards,
            accessibilityMode: accessibilityMode
        ) {
            return exitRoute
        }

        if let refugeRoute = bestRoute(
            in: building,
            startNodeID: startNodeID,
            destinations: building.refugePoints.compactMap { building.node(id: $0.nodeID) },
            activeHazards: activeHazards,
            accessibilityMode: accessibilityMode
        ) {
            return refugeRoute
        }

        throw RoutingError.noRouteAvailable
    }

    private func bestRoute(
        in building: BuildingPackage,
        startNodeID: String,
        destinations: [Node],
        activeHazards: [HazardEvent],
        accessibilityMode: Bool
    ) -> RouteResult? {
        let graph = WeightedGraph(
            building: building,
            activeHazards: activeHazards,
            accessibilityMode: accessibilityMode
        )

        let candidateRoutes = destinations.compactMap { destination -> RouteResult? in
            guard let path = graph.shortestPath(from: startNodeID, to: destination.id) else {
                return nil
            }

            let nodes = path.compactMap { building.node(id: $0) }
            let distance = graph.pathDistance(path)
            let instructions = makeInstructions(from: nodes, destination: destination)
            let kind: DestinationKind = destination.type == .refugePoint ? .refugePoint : .exit

            return RouteResult(
                destinationNode: destination,
                destinationKind: kind,
                path: nodes,
                totalDistance: distance,
                instructions: instructions
            )
        }

        return candidateRoutes.min(by: { $0.totalDistance < $1.totalDistance })
    }

    private func makeInstructions(from nodes: [Node], destination: Node) -> [RouteInstruction] {
        guard let first = nodes.first else { return [] }
        var result: [RouteInstruction] = [
            RouteInstruction(
                title: "Start at \(first.name)",
                detail: "Follow the highlighted path and keep moving toward \(destination.name)."
            )
        ]

        for node in nodes.dropFirst() {
            result.append(
                RouteInstruction(
                    title: "Continue to \(node.name)",
                    detail: guidanceText(for: node)
                )
            )
        }

        return result
    }

    private func guidanceText(for node: Node) -> String {
        switch node.type {
        case .exit:
            return "Exit the building and follow official emergency instructions."
        case .refugePoint:
            return "Stay at the refuge point, alert responders, and wait for assistance."
        case .stairwell:
            return "Use the stairwell and keep to the left."
        case .intersection:
            return "Proceed through the corridor intersection."
        case .lift:
            return "Only use the lift if emergency procedures allow it."
        case .room:
            return "Move through the room anchor toward the next corridor."
        }
    }
}

private struct WeightedGraph {
    private struct EdgeCost {
        let destination: String
        let weight: Double
    }

    private let adjacency: [String: [EdgeCost]]

    init(building: BuildingPackage, activeHazards: [HazardEvent], accessibilityMode: Bool) {
        let blockedNodes = Set(
            activeHazards
                .filter { $0.severity == .blocked || $0.severity == .inaccessible }
                .flatMap(\.targetNodeIDs)
        )
        let blockedEdges = Set(
            activeHazards
                .filter { $0.severity == .blocked || $0.severity == .inaccessible }
                .flatMap(\.targetEdgeIDs)
        )
        let penalizedEdges = Dictionary(
            activeHazards
                .filter { $0.severity == .highRisk }
                .flatMap { hazard in
                    hazard.targetEdgeIDs.map { ($0, hazard.severity.multiplier) }
                },
            uniquingKeysWith: max
        )
        let penalizedNodes = Dictionary(
            activeHazards
                .filter { $0.severity == .highRisk }
                .flatMap { hazard in
                    hazard.targetNodeIDs.map { ($0, hazard.severity.multiplier) }
                },
            uniquingKeysWith: max
        )

        var adjacency: [String: [EdgeCost]] = [:]

        for edge in building.edges {
            guard !blockedEdges.contains(edge.id) else { continue }
            guard !blockedNodes.contains(edge.fromNodeID), !blockedNodes.contains(edge.toNodeID) else { continue }
            guard !accessibilityMode || edge.accessibilityFlags.wheelchairAccessible else { continue }

            let fromNode = building.node(id: edge.fromNodeID)
            let toNode = building.node(id: edge.toNodeID)

            if accessibilityMode && (fromNode?.type == .stairwell || toNode?.type == .stairwell) {
                continue
            }

            let edgePenalty = penalizedEdges[edge.id] ?? 1.0
            let fromPenalty = penalizedNodes[edge.fromNodeID] ?? 1.0
            let toPenalty = penalizedNodes[edge.toNodeID] ?? 1.0
            let totalWeight = edge.distance * max(edgePenalty, fromPenalty, toPenalty)

            adjacency[edge.fromNodeID, default: []].append(EdgeCost(destination: edge.toNodeID, weight: totalWeight))
            adjacency[edge.toNodeID, default: []].append(EdgeCost(destination: edge.fromNodeID, weight: totalWeight))
        }

        self.adjacency = adjacency
    }

    func shortestPath(from start: String, to end: String) -> [String]? {
        var distances: [String: Double] = [start: 0]
        var previous: [String: String] = [:]
        var unvisited = Set(adjacency.keys)
        unvisited.insert(start)
        unvisited.insert(end)

        while let current = unvisited.min(by: { (distances[$0] ?? .infinity) < (distances[$1] ?? .infinity) }) {
            if current == end {
                return buildPath(previous: previous, end: end)
            }

            unvisited.remove(current)

            guard let currentDistance = distances[current], currentDistance.isFinite else {
                break
            }

            for neighbor in adjacency[current] ?? [] {
                let candidate = currentDistance + neighbor.weight
                if candidate < (distances[neighbor.destination] ?? .infinity) {
                    distances[neighbor.destination] = candidate
                    previous[neighbor.destination] = current
                    unvisited.insert(neighbor.destination)
                }
            }
        }

        return nil
    }

    func pathDistance(_ path: [String]) -> Double {
        guard path.count > 1 else { return 0 }

        var total = 0.0
        for pair in zip(path, path.dropFirst()) {
            if let edge = adjacency[pair.0]?.first(where: { $0.destination == pair.1 }) {
                total += edge.weight
            }
        }
        return total
    }

    private func buildPath(previous: [String: String], end: String) -> [String] {
        var path = [end]
        var current = end

        while let prior = previous[current] {
            path.append(prior)
            current = prior
        }

        return path.reversed()
    }
}
