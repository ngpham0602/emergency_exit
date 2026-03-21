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
    case addNode, setStart, markDanger, markExit, delete

    var label: String {
        switch self {
        case .addNode:    return "Add Node"
        case .setStart:   return "I'm Here"
        case .markDanger: return "Danger"
        case .markExit:   return "Exit"
        case .delete:     return "Delete"
        }
    }

    var icon: String {
        switch self {
        case .addNode:    return "plus.circle.fill"
        case .setStart:   return "person.fill"
        case .markDanger: return "exclamationmark.triangle.fill"
        case .markExit:   return "door.right.hand.open"
        case .delete:     return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .addNode:    return .blue
        case .setStart:   return Color(red: 0.22, green: 0.96, blue: 0.29)
        case .markDanger: return Color(red: 0.90, green: 0.25, blue: 0.25)
        case .markExit:   return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .delete:     return Color(red: 0.90, green: 0.25, blue: 0.25)
        }
    }
}

// MARK: - ViewModel

enum SyncStatus {
    case idle, syncing, synced, error(String)
    var icon:  String { switch self { case .synced: return "checkmark.icloud.fill"
                                      case .syncing: return "arrow.triangle.2.circlepath"
                                      case .error:   return "exclamationmark.icloud.fill"
                                      case .idle:    return "icloud" } }
    var color: Color  { switch self { case .synced: return Color(red: 0.22, green: 0.96, blue: 0.29)
                                      case .syncing: return .yellow
                                      case .error:   return Color(red: 0.9, green: 0.25, blue: 0.25)
                                      case .idle:    return Color(white: 0.4) } }
}

@MainActor
final class MapEditorViewModel: ObservableObject {
    @Published var nodes:       [CustomNode] = []
    @Published var startNodeID: String?
    @Published var routePath:   [String]     = []
    @Published var syncStatus:  SyncStatus   = .idle

    // Normalised distance threshold — nodes within this distance are auto-connected
    private let proximityThreshold: Double = 0.13

    private(set) var mapID: String = "default"
    private let db = FirestoreService.shared
    private let nodesKey = "map_editor_nodes_v2"

    init() { loadLocal() }

    // MARK: Load from Firestore

    func loadFromFirestore(mapID: String) async {
        self.mapID = mapID
        syncStatus = .syncing
        do {
            let fetchedNodes = try await db.fetchCustomNodes(mapID: mapID)
            nodes = fetchedNodes
            saveLocal()
            syncStatus = .synced
        } catch {
            loadLocal()
            syncStatus = .error("Loaded from cache")
        }
        recomputeRoute()
    }

    // MARK: CRUD — each mutation saves locally + syncs to Firestore

    func addNode(nx: Double, ny: Double) -> String {
        let n = CustomNode(nx: nx, ny: ny, label: "N\(nodes.count + 1)")
        nodes.append(n)
        saveLocal(); recomputeRoute()
        syncNode(n)
        return n.id
    }

    func toggleDangerNode(_ id: String) {
        guard let i = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[i].isDanger.toggle()
        saveLocal(); recomputeRoute()
        syncNode(nodes[i])
    }

    func toggleExit(_ id: String) {
        guard let i = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[i].isExit.toggle()
        saveLocal(); recomputeRoute()
        syncNode(nodes[i])
    }

    func deleteNode(_ id: String) {
        nodes.removeAll { $0.id == id }
        if startNodeID == id { startNodeID = nil }
        saveLocal(); recomputeRoute()
        Task {
            syncStatus = .syncing
            do { try await db.deleteCustomNode(nodeID: id, mapID: mapID); syncStatus = .synced }
            catch { syncStatus = .error(error.localizedDescription) }
        }
    }

    func setStart(_ id: String) { startNodeID = id; recomputeRoute() }

    func clearAll() {
        let mid = mapID
        nodes = []; startNodeID = nil; routePath = []
        saveLocal()
        Task {
            syncStatus = .syncing
            do { try await db.clearCustomGraph(mapID: mid); syncStatus = .synced }
            catch { syncStatus = .error(error.localizedDescription) }
        }
    }

    // MARK: Proximity graph builder — returns all auto-connected pairs

    func proximityPairs() -> [(CustomNode, CustomNode)] {
        var pairs: [(CustomNode, CustomNode)] = []
        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let d = hypot(nodes[i].nx - nodes[j].nx, nodes[i].ny - nodes[j].ny)
                if d <= proximityThreshold { pairs.append((nodes[i], nodes[j])) }
            }
        }
        return pairs
    }

    // MARK: Pathfinding — Dijkstra on auto proximity graph
    // Danger nodes get 10,000× weight penalty so the route avoids them when possible

    func recomputeRoute() {
        guard let start = startNodeID,
              nodes.contains(where: { $0.id == start })
        else { routePath = []; return }

        let exits = nodes.filter { $0.isExit }
        guard !exits.isEmpty else { routePath = []; return }

        let dangerSet = Set(nodes.filter { $0.isDanger }.map { $0.id })

        var adj: [String: [(String, Double)]] = [:]
        for n in nodes { adj[n.id] = [] }

        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let ni = nodes[i], nj = nodes[j]
                let dist = hypot(ni.nx - nj.nx, ni.ny - nj.ny)
                guard dist <= proximityThreshold else { continue }
                let danger = dangerSet.contains(ni.id) || dangerSet.contains(nj.id)
                let w = dist * (danger ? 10_000.0 : 1.0)
                adj[ni.id]?.append((nj.id, w))
                adj[nj.id]?.append((ni.id, w))
            }
        }

        var best: [String] = []
        var bestCost = Double.infinity
        for exit in exits {
            if let (cost, path) = dijkstra(from: start, to: exit.id, adj: adj),
               cost < bestCost { bestCost = cost; best = path }
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
                var path: [String] = []; var cur: String? = dst
                while let c = cur { path.append(c); cur = prev[c] }
                return (d, path.reversed())
            }
            for (v, w) in adj[u] ?? [] {
                let alt = d + w
                if alt < (dist[v] ?? .infinity) {
                    dist[v] = alt; prev[v] = u; queue.append((v, alt))
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

    func canvasPoint(_ n: CustomNode, in sz: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(n.nx) * sz.width, y: CGFloat(n.ny) * sz.height)
    }

    // MARK: Private helpers

    private func syncNode(_ node: CustomNode) {
        let mid = mapID
        Task {
            syncStatus = .syncing
            do { try await db.setCustomNode(node, mapID: mid); syncStatus = .synced }
            catch { syncStatus = .error(error.localizedDescription) }
        }
    }

    private func nodeDist(_ n: CustomNode, _ pt: CGPoint, _ sz: CGSize) -> CGFloat {
        hypot(CGFloat(n.nx) * sz.width - pt.x, CGFloat(n.ny) * sz.height - pt.y)
    }

    private func saveLocal() {
        if let d = try? JSONEncoder().encode(nodes) { UserDefaults.standard.set(d, forKey: nodesKey) }
    }

    private func loadLocal() {
        if let d = UserDefaults.standard.data(forKey: nodesKey),
           let n = try? JSONDecoder().decode([CustomNode].self, from: d) { nodes = n }
    }
}

// MARK: - MapEditorView

struct MapEditorView: View {
    @EnvironmentObject private var floorPlanVM: FloorPlanLibraryViewModel
    @StateObject private var vm = MapEditorViewModel()

    @State private var mode:      EditorMode = .addNode
    @State private var showClear  = false

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
                                      nodes: vm.nodes,
                                      proximityPairs: vm.proximityPairs(),
                                      routePath: vm.routePath,
                                      startID: vm.startNodeID)
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
        .task {
            let mapID = floorPlanVM.activeMapID ?? "default"
            await vm.loadFromFirestore(mapID: mapID)
        }
        .onChange(of: floorPlanVM.activeMapID) { newID in
            Task { await vm.loadFromFirestore(mapID: newID ?? "default") }
        }
        .confirmationDialog("Clear all nodes?",
                            isPresented: $showClear, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { vm.clearAll() }
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

            // Sync status
            Image(systemName: vm.syncStatus.icon)
                .font(.system(size: 14))
                .foregroundStyle(vm.syncStatus.color)

            Text("\(vm.nodes.count) nodes")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textDim)

            // Clear everything
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
            case .addNode:    return "Tap empty space to place a node — nearby nodes auto-connect"
            case .setStart:   return "Tap a node to set your current location"
            case .markDanger: return "Tap a node to toggle danger — route will avoid it"
            case .markExit:   return "Tap a node to mark it as a safe exit (amber)"
            case .delete:     return "Tap a node to delete it"
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
                    Button { mode = m } label: {
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

        case .setStart:
            if let node = vm.nearestNode(to: pt, in: size) { vm.setStart(node.id) }

        case .markDanger:
            if let node = vm.nearestNode(to: pt, in: size) { vm.toggleDangerNode(node.id) }

        case .markExit:
            if let node = vm.nearestNode(to: pt, in: size) { vm.toggleExit(node.id) }

        case .delete:
            if let node = vm.nearestNode(to: pt, in: size) { vm.deleteNode(node.id) }
        }
    }

    // MARK: Canvas drawing

    private func drawGraph(ctx: inout GraphicsContext, size: CGSize,
                           nodes: [CustomNode],
                           proximityPairs: [(CustomNode, CustomNode)],
                           routePath: [String],
                           startID: String?) {
        let nodeMap    = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let routeNodes = Set(routePath)

        let green = Color(red: 0.22, green: 0.96, blue: 0.29)
        let red   = Color(red: 0.90, green: 0.25, blue: 0.25)
        let amber = Color(red: 0.96, green: 0.62, blue: 0.04)

        // Build route segment set for O(1) lookup: "id1|id2" (sorted)
        var routeSegments = Set<String>()
        for i in 0..<max(0, routePath.count - 1) {
            let a = routePath[i], b = routePath[i+1]
            routeSegments.insert([a, b].sorted().joined(separator: "|"))
        }

        // 1 — Draw proximity connections
        for (ni, nj) in proximityPairs {
            let a = pt(ni, size), b = pt(nj, size)
            let key = [ni.id, nj.id].sorted().joined(separator: "|")
            let isRoute = routeSegments.contains(key)

            var line = Path()
            line.move(to: a)
            line.addLine(to: b)

            if isRoute {
                ctx.stroke(line, with: .color(green),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round))
            } else {
                // Faint gray — shows the auto-graph to the user
                ctx.stroke(line, with: .color(Color(white: 0.30)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }

        // 2 — Draw route direction arrows
        if routePath.count >= 2 {
            for i in 0..<routePath.count - 1 {
                guard let fn = nodeMap[routePath[i]],
                      let tn = nodeMap[routePath[i+1]] else { continue }
                drawArrow(ctx: &ctx, from: pt(fn, size), to: pt(tn, size), color: green)
            }
        }

        // 3 — Draw nodes
        for node in nodes {
            let center = pt(node, size)
            let r: CGFloat = 10
            let isStart = node.id == startID
            let onRoute = routeNodes.contains(node.id)

            if isStart {
                let circ = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                   width: r*2, height: r*2))
                ctx.fill(circ, with: .color(green))
                ctx.stroke(circ, with: .color(.white), lineWidth: 1.5)

                let pr: CGFloat = 16
                let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                    width: pr*2, height: pr*2))
                ctx.stroke(pulse, with: .color(green.opacity(0.4)), lineWidth: 1.5)

                let lbl = Text("YOU")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(green)
                ctx.draw(lbl, at: CGPoint(x: center.x, y: center.y - r - 9))

            } else if node.isExit {
                let s: CGFloat = 11
                var diamond = Path()
                diamond.move(to: CGPoint(x: center.x,       y: center.y - s))
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
                let circ = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                   width: r*2, height: r*2))
                ctx.fill(circ, with: .color(Color(white: 0.18)))
                ctx.stroke(circ,
                           with: .color(onRoute ? green : Color(white: 0.42)),
                           lineWidth: onRoute ? 2 : 1.5)
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

    // Arrow head at midpoint of a segment
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
}

#Preview {
    MapEditorView()
        .environmentObject(FloorPlanLibraryViewModel())
}
