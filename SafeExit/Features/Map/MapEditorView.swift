import SwiftUI

// MARK: - Data models

struct CustomNode: Identifiable, Codable {
    var id:       String = UUID().uuidString
    var nx:       Double          // normalised 0–1 of canvas width
    var ny:       Double          // normalised 0–1 of canvas height
    var isDanger: Bool   = false
    var isExit:   Bool   = false
    var label:    String = ""
}

struct CustomEdge: Identifiable, Codable {
    var id:       String = UUID().uuidString
    var fromID:   String
    var toID:     String
    var isDanger: Bool   = false
}

// MARK: - Editor modes

enum EditorMode: CaseIterable, Equatable {
    case addNode, addEdge, setStart, markDanger, markExit, delete

    var label: String {
        switch self {
        case .addNode:    return "Add Node"
        case .addEdge:    return "Add Edge"
        case .setStart:   return "I'm Here"
        case .markDanger: return "Danger"
        case .markExit:   return "Exit"
        case .delete:     return "Delete"
        }
    }

    var icon: String {
        switch self {
        case .addNode:    return "plus.circle.fill"
        case .addEdge:    return "line.diagonal"
        case .setStart:   return "person.fill"
        case .markDanger: return "exclamationmark.triangle.fill"
        case .markExit:   return "door.right.hand.open"
        case .delete:     return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .addNode:    return .blue
        case .addEdge:    return .purple
        case .setStart:   return Color(red: 0.22, green: 0.96, blue: 0.29)
        case .markDanger: return Color(red: 0.90, green: 0.25, blue: 0.25)
        case .markExit:   return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .delete:     return Color(red: 0.90, green: 0.25, blue: 0.25)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class MapEditorViewModel: ObservableObject {
    @Published var nodes:       [CustomNode] = []
    @Published var edges:       [CustomEdge] = []
    @Published var startNodeID: String?
    @Published var routePath:   [String]     = []   // ordered node IDs

    private let nodesKey = "map_editor_nodes_v1"
    private let edgesKey = "map_editor_edges_v1"

    init() { load() }

    // MARK: CRUD

    func addNode(nx: Double, ny: Double) -> String {
        let n = CustomNode(nx: nx, ny: ny, label: "N\(nodes.count + 1)")
        nodes.append(n); save()
        return n.id
    }

    func addEdge(from a: String, to b: String) {
        guard a != b,
              !edges.contains(where: {
                  ($0.fromID == a && $0.toID == b) ||
                  ($0.fromID == b && $0.toID == a)
              })
        else { return }
        edges.append(CustomEdge(fromID: a, toID: b))
        save(); recomputeRoute()
    }

    func toggleDangerNode(_ id: String) {
        guard let i = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[i].isDanger.toggle(); save(); recomputeRoute()
    }

    func toggleDangerEdge(_ id: String) {
        guard let i = edges.firstIndex(where: { $0.id == id }) else { return }
        edges[i].isDanger.toggle(); save(); recomputeRoute()
    }

    func toggleExit(_ id: String) {
        guard let i = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[i].isExit.toggle(); save(); recomputeRoute()
    }

    func deleteNode(_ id: String) {
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.fromID == id || $0.toID == id }
        if startNodeID == id { startNodeID = nil }
        save(); recomputeRoute()
    }

    func deleteEdge(_ id: String) {
        edges.removeAll { $0.id == id }; save(); recomputeRoute()
    }

    func setStart(_ id: String) { startNodeID = id; recomputeRoute() }

    func clearAll() {
        nodes = []; edges = []; startNodeID = nil; routePath = []; save()
    }

    // MARK: Pathfinding — Dijkstra with danger penalty

    func recomputeRoute() {
        guard let start = startNodeID,
              nodes.contains(where: { $0.id == start })
        else { routePath = []; return }

        let exits = nodes.filter { $0.isExit }
        guard !exits.isEmpty else { routePath = []; return }

        let dangerNodeSet = Set(nodes.filter { $0.isDanger }.map { $0.id })
        let dangerEdgeSet = Set(edges.filter { $0.isDanger }.map { $0.id })

        var adj: [String: [(String, Double)]] = [:]
        for n in nodes { adj[n.id] = [] }
        for edge in edges {
            guard let fn = nodes.first(where: { $0.id == edge.fromID }),
                  let tn = nodes.first(where: { $0.id == edge.toID })
            else { continue }
            let dist = hypot(fn.nx - tn.nx, fn.ny - tn.ny)
            let danger = dangerEdgeSet.contains(edge.id)
                      || dangerNodeSet.contains(fn.id)
                      || dangerNodeSet.contains(tn.id)
            let w = dist * (danger ? 10_000.0 : 1.0)
            adj[fn.id]?.append((tn.id, w))
            adj[tn.id]?.append((fn.id, w))
        }

        var best: [String] = []
        var bestCost = Double.infinity
        for exit in exits {
            if let (cost, path) = dijkstra(from: start, to: exit.id, adj: adj),
               cost < bestCost {
                bestCost = cost; best = path
            }
        }
        routePath = best
    }

    private func dijkstra(from src: String, to dst: String,
                          adj: [String: [(String, Double)]]) -> (Double, [String])? {
        var dist:    [String: Double] = [src: 0]
        var prev:    [String: String] = [:]
        var visited: Set<String>      = []
        var queue: [(id: String, cost: Double)] = [(src, 0)]

        while !queue.isEmpty {
            queue.sort { $0.cost < $1.cost }
            let (u, d) = queue.removeFirst()
            guard !visited.contains(u) else { continue }
            visited.insert(u)

            if u == dst {
                var path: [String] = []
                var cur: String? = dst
                while let c = cur { path.append(c); cur = prev[c] }
                return (d, path.reversed())
            }

            for (v, w) in adj[u] ?? [] {
                let alt = d + w
                if alt < (dist[v] ?? .infinity) {
                    dist[v] = alt; prev[v] = u
                    queue.append((v, alt))
                }
            }
        }
        return nil
    }

    // MARK: Hit-testing

    func nearestNode(to pt: CGPoint, in sz: CGSize, threshold: CGFloat = 26) -> CustomNode? {
        guard let c = nodes.min(by: { nodeDist($0, pt, sz) < nodeDist($1, pt, sz) }),
              nodeDist(c, pt, sz) <= threshold else { return nil }
        return c
    }

    func nearestEdge(to pt: CGPoint, in sz: CGSize, threshold: CGFloat = 14) -> CustomEdge? {
        let map = nodeDict()
        guard let c = edges.min(by: { edgeDist($0, pt, sz, map) < edgeDist($1, pt, sz, map) }),
              edgeDist(c, pt, sz, map) <= threshold else { return nil }
        return c
    }

    func canvasPoint(_ n: CustomNode, in sz: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(n.nx) * sz.width, y: CGFloat(n.ny) * sz.height)
    }

    // MARK: Helpers

    func nodeDict() -> [String: CustomNode] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    }

    func routeEdgeIDs() -> Set<String> {
        var result = Set<String>()
        let ids = routePath
        for i in 0 ..< max(0, ids.count - 1) {
            for e in edges where
                (e.fromID == ids[i] && e.toID == ids[i+1]) ||
                (e.fromID == ids[i+1] && e.toID == ids[i]) {
                result.insert(e.id)
            }
        }
        return result
    }

    private func nodeDist(_ n: CustomNode, _ pt: CGPoint, _ sz: CGSize) -> CGFloat {
        hypot(CGFloat(n.nx) * sz.width - pt.x, CGFloat(n.ny) * sz.height - pt.y)
    }

    private func edgeDist(_ e: CustomEdge, _ pt: CGPoint, _ sz: CGSize,
                           _ map: [String: CustomNode]) -> CGFloat {
        guard let fn = map[e.fromID], let tn = map[e.toID] else { return .infinity }
        let a = CGPoint(x: fn.nx * sz.width,  y: fn.ny * sz.height)
        let b = CGPoint(x: tn.nx * sz.width,  y: tn.ny * sz.height)
        return ptSegDist(pt, a, b)
    }

    private func ptSegDist(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lenSq = dx*dx + dy*dy
        guard lenSq > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x)*dx + (p.y - a.y)*dy) / lenSq))
        return hypot(p.x - a.x - t*dx, p.y - a.y - t*dy)
    }

    // MARK: Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(nodes) { UserDefaults.standard.set(d, forKey: nodesKey) }
        if let d = try? JSONEncoder().encode(edges) { UserDefaults.standard.set(d, forKey: edgesKey) }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: nodesKey),
           let n = try? JSONDecoder().decode([CustomNode].self, from: d) { nodes = n }
        if let d = UserDefaults.standard.data(forKey: edgesKey),
           let e = try? JSONDecoder().decode([CustomEdge].self, from: d) { edges = e }
    }
}

// MARK: - MapEditorView

struct MapEditorView: View {
    @EnvironmentObject private var floorPlanVM: FloorPlanLibraryViewModel
    @StateObject private var vm = MapEditorViewModel()

    @State private var mode:            EditorMode = .addNode
    @State private var pendingNodeID:   String?        // first node picked in addEdge mode
    @State private var showClear =      false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        // Background floor plan image
                        if let img = floorPlanVM.activeMapImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size.width, height: size.height)
                                .clipped()
                                .opacity(0.38)
                        } else {
                            AppTheme.cardBg
                        }

                        // Graph drawing canvas
                        Canvas { ctx, sz in
                            drawGraph(ctx: &ctx, size: sz,
                                      nodes: vm.nodes, edges: vm.edges,
                                      routePath: vm.routePath,
                                      startID: vm.startNodeID,
                                      pendingID: pendingNodeID)
                        }
                        .allowsHitTesting(false)

                        // Tap-detection overlay
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { val in handleTap(val.location, in: size) }
                            )

                        // "No floor plan" hint
                        if floorPlanVM.activeMapImage == nil {
                            VStack(spacing: 6) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.textDim)
                                Text("No active floor plan")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSec)
                                Text("Go to Plans tab to import one")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textDim)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .allowsHitTesting(false)
                        }
                    }
                }
                .background(AppTheme.cardBg)

                routeBanner
                hintBar
                modeToolbar
            }
        }
        .confirmationDialog("Clear all nodes and edges?",
                            isPresented: $showClear, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { vm.clearAll(); pendingNodeID = nil }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                Image(systemName: "map.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.bg)
            }
            Text("Map Editor")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPri)

            Spacer()

            Text("\(vm.nodes.count) nodes · \(vm.edges.count) edges")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textDim)

            Button { showClear = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.red)
                    .padding(7)
                    .background(AppTheme.redDim)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: Route banner

    @ViewBuilder
    private var routeBanner: some View {
        if !vm.routePath.isEmpty {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.green)
                        .frame(width: 34, height: 34)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(AppTheme.bg)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("SAFEST ROUTE FOUND")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.green)
                    Text("\(vm.routePath.count - 1) steps to nearest exit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPri)
                }
                Spacer()
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .foregroundStyle(AppTheme.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.green.opacity(0.08))
            .overlay(alignment: .top) { Rectangle().fill(AppTheme.green.opacity(0.2)).frame(height: 1) }
        } else if vm.startNodeID != nil && vm.nodes.contains(where: { $0.isExit }) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.octagon.fill").foregroundStyle(AppTheme.red)
                Text("No connected path to any exit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPri)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.redDim)
            .overlay(alignment: .top) { Rectangle().fill(AppTheme.red.opacity(0.2)).frame(height: 1) }
        }
    }

    // MARK: Hint bar

    private var hintBar: some View {
        let hint: String = {
            switch mode {
            case .addNode:    return "Tap empty space to place a node"
            case .addEdge:    return pendingNodeID == nil
                                   ? "Tap a node to start an edge"
                                   : "Tap another node to connect — tap same to cancel"
            case .setStart:   return "Tap a node to set your location"
            case .markDanger: return "Tap a node or edge to toggle danger"
            case .markExit:   return "Tap a node to mark it as a safe exit (amber)"
            case .delete:     return "Tap a node or edge to delete it"
            }
        }()

        return HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(mode.color)
            Text(hint)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.cardBg2)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.divider).frame(height: 1) }
    }

    // MARK: Mode toolbar

    private var modeToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EditorMode.allCases, id: \.label) { m in
                    Button {
                        mode = m
                        if m != .addEdge { pendingNodeID = nil }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: m.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(m.label)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(mode == m ? m.color : AppTheme.textDim)
                        .frame(width: 72, height: 56)
                        .background(mode == m ? m.color.opacity(0.12) : AppTheme.cardBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(mode == m ? m.color.opacity(0.4) : AppTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AppTheme.cardBg)
    }

    // MARK: Tap handling

    private func handleTap(_ pt: CGPoint, in size: CGSize) {
        switch mode {

        case .addNode:
            if vm.nearestNode(to: pt, in: size) == nil {
                _ = vm.addNode(nx: Double(pt.x / size.width),
                               ny: Double(pt.y / size.height))
            }

        case .addEdge:
            guard let node = vm.nearestNode(to: pt, in: size) else { return }
            if let first = pendingNodeID {
                if first == node.id {
                    pendingNodeID = nil         // tapped same node → cancel
                } else {
                    vm.addEdge(from: first, to: node.id)
                    pendingNodeID = nil
                }
            } else {
                pendingNodeID = node.id
            }

        case .setStart:
            if let node = vm.nearestNode(to: pt, in: size) { vm.setStart(node.id) }

        case .markDanger:
            if let node = vm.nearestNode(to: pt, in: size) {
                vm.toggleDangerNode(node.id)
            } else if let edge = vm.nearestEdge(to: pt, in: size) {
                vm.toggleDangerEdge(edge.id)
            }

        case .markExit:
            if let node = vm.nearestNode(to: pt, in: size) { vm.toggleExit(node.id) }

        case .delete:
            if let node = vm.nearestNode(to: pt, in: size) {
                vm.deleteNode(node.id)
                if pendingNodeID == node.id { pendingNodeID = nil }
            } else if let edge = vm.nearestEdge(to: pt, in: size) {
                vm.deleteEdge(edge.id)
            }
        }
    }

    // MARK: Canvas drawing (pure function — captures only value types)

    private func drawGraph(ctx: inout GraphicsContext, size: CGSize,
                           nodes: [CustomNode], edges: [CustomEdge],
                           routePath: [String], startID: String?,
                           pendingID: String?) {
        let nodeMap     = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let routeEdges  = routeEdgeSet(routePath: routePath, edges: edges)
        let routeNodes  = Set(routePath)

        let green  = Color(red: 0.22, green: 0.96, blue: 0.29)
        let red    = Color(red: 0.90, green: 0.25, blue: 0.25)
        let amber  = Color(red: 0.96, green: 0.62, blue: 0.04)

        // 1 — Draw edges
        for edge in edges {
            guard let fn = nodeMap[edge.fromID], let tn = nodeMap[edge.toID] else { continue }
            let a = pt(fn, size); let b = pt(tn, size)
            var line = Path(); line.move(to: a); line.addLine(to: b)

            if routeEdges.contains(edge.id) {
                ctx.stroke(line, with: .color(green),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            } else if edge.isDanger {
                ctx.stroke(line, with: .color(red),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
            } else {
                ctx.stroke(line, with: .color(Color(white: 0.35)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }

        // 2 — Draw route direction arrows
        if routePath.count >= 2 {
            for i in 0 ..< routePath.count - 1 {
                guard let fn = nodeMap[routePath[i]],
                      let tn = nodeMap[routePath[i+1]] else { continue }
                drawArrow(ctx: &ctx, from: pt(fn, size), to: pt(tn, size), color: green)
            }
        }

        // 3 — Draw nodes
        for node in nodes {
            let center = pt(node, size)
            let r: CGFloat = 10
            let isStart    = node.id == startID
            let isSelected = node.id == pendingID
            let onRoute    = routeNodes.contains(node.id)

            if isStart {
                // Bright green filled circle
                let circ = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                   width: r*2, height: r*2))
                ctx.fill(circ, with: .color(green))
                ctx.stroke(circ, with: .color(.white), lineWidth: 1.5)

                // Outer pulse
                let pr: CGFloat = 16
                let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                    width: pr*2, height: pr*2))
                ctx.stroke(pulse, with: .color(green.opacity(0.4)), lineWidth: 1.5)

                let lbl = Text("YOU")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(green)
                ctx.draw(lbl, at: CGPoint(x: center.x, y: center.y - r - 9))

            } else if node.isExit {
                // Amber diamond
                let s: CGFloat = 11
                var diamond = Path()
                diamond.move(to: CGPoint(x: center.x,     y: center.y - s))
                diamond.addLine(to: CGPoint(x: center.x + s, y: center.y))
                diamond.addLine(to: CGPoint(x: center.x,     y: center.y + s))
                diamond.addLine(to: CGPoint(x: center.x - s, y: center.y))
                diamond.closeSubpath()
                ctx.fill(diamond, with: .color(amber.opacity(0.2)))
                ctx.stroke(diamond, with: .color(amber), lineWidth: 2)

                let lbl = Text("EXIT")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundStyle(amber)
                ctx.draw(lbl, at: CGPoint(x: center.x, y: center.y + s + 9))

            } else if node.isDanger {
                // Red circle + dashed ring
                let circ = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                   width: r*2, height: r*2))
                ctx.fill(circ, with: .color(red.opacity(0.18)))
                ctx.stroke(circ, with: .color(red), lineWidth: 2)

                let hr: CGFloat = 17
                let ring = Path(ellipseIn: CGRect(x: center.x - hr, y: center.y - hr,
                                                   width: hr*2, height: hr*2))
                ctx.stroke(ring, with: .color(red.opacity(0.45)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

                let lbl = Text("⚠")
                    .font(.system(size: 11))
                ctx.draw(lbl, at: CGPoint(x: center.x, y: center.y - r - 10))

            } else {
                // Regular node
                let circ = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                   width: r*2, height: r*2))
                ctx.fill(circ, with: .color(Color(white: 0.18)))
                ctx.stroke(circ,
                           with: .color(onRoute ? green : Color(white: 0.42)),
                           lineWidth: onRoute ? 2 : 1.5)
            }

            // Blue dashed ring — node is selected as edge start
            if isSelected {
                let sr: CGFloat = 17
                let ring = Path(ellipseIn: CGRect(x: center.x - sr, y: center.y - sr,
                                                   width: sr*2, height: sr*2))
                ctx.stroke(ring, with: .color(.blue),
                           style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }

            // Node label
            if !node.label.isEmpty {
                let lbl = Text(node.label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
                ctx.draw(lbl, at: CGPoint(x: center.x, y: center.y + r + 9))
            }
        }
    }

    // Arrow head at the midpoint of a segment
    private func drawArrow(ctx: inout GraphicsContext,
                           from a: CGPoint, to b: CGPoint, color: Color) {
        let mid   = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let angle = atan2(b.y - a.y, b.x - a.x)
        let len: CGFloat = 8, wing: CGFloat = .pi / 6
        let p1 = CGPoint(x: mid.x - len * cos(angle - wing),
                         y: mid.y - len * sin(angle - wing))
        let p2 = CGPoint(x: mid.x - len * cos(angle + wing),
                         y: mid.y - len * sin(angle + wing))
        var arrow = Path()
        arrow.move(to: p1); arrow.addLine(to: mid); arrow.addLine(to: p2)
        ctx.stroke(arrow, with: .color(color),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func pt(_ n: CustomNode, _ sz: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(n.nx) * sz.width, y: CGFloat(n.ny) * sz.height)
    }

    private func routeEdgeSet(routePath: [String], edges: [CustomEdge]) -> Set<String> {
        var result = Set<String>()
        for i in 0 ..< max(0, routePath.count - 1) {
            for e in edges where
                (e.fromID == routePath[i] && e.toID == routePath[i+1]) ||
                (e.fromID == routePath[i+1] && e.toID == routePath[i]) {
                result.insert(e.id)
            }
        }
        return result
    }
}

#Preview {
    MapEditorView()
        .environmentObject(FloorPlanLibraryViewModel())
}
