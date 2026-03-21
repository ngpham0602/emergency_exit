import SwiftUI

// MARK: - Shared coordinate mapper (used by canvas drawing AND tap detection)

private func mapNodeToPoint(_ coords: Coordinates, in canvasSize: CGSize) -> CGPoint {
    let minX = 2.0, maxX = 63.0, minY = 1.0, maxY = 29.0, padding = 28.0
    let usableW = canvasSize.width  - padding * 2
    let usableH = canvasSize.height - padding * 2
    let x = padding + ((coords.x - minX) / (maxX - minX)) * usableW
    let y = padding + ((coords.y - minY) / (maxY - minY)) * usableH
    return CGPoint(x: x, y: y)
}

// MARK: - Map interaction mode

private enum MapMode {
    case myLocation   // tap a node → set as start
    case danger       // tap a node → open hazard picker
}

// MARK: - Sheet state

private enum MapSheet: Identifiable {
    case hazardPicker(Node)

    var id: String {
        switch self {
        case .hazardPicker(let n): return "hazard-\(n.id)"
        }
    }
}

// MARK: - LiveMapView

struct LiveMapView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var floorPlanVM: FloorPlanLibraryViewModel
    @State private var activeSheet: MapSheet?
    @State private var mapMode: MapMode = .myLocation

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 34, height: 34)
                        Image(systemName: "shield.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.bg)
                    }

                    Text("Live Map")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPri)

                    Spacer()

                    Circle()
                        .fill(AppTheme.greenDim)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "info")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.green)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                // Map canvas
                GeometryReader { geo in
                    let canvasH = geo.size.height - 90
                    let canvasSize = CGSize(width: geo.size.width, height: canvasH)

                    ZStack(alignment: .bottomLeading) {
                        // Floor plan
                        FloorPlanCanvas(
                            building: viewModel.buildingPackage,
                            routePath: viewModel.routeResult?.path ?? [],
                            activeHazards: viewModel.activeHazards,
                            selectedNodeID: viewModel.selectedStartNodeID,
                            canvasSize: canvasSize,
                            mapImage: floorPlanVM.activeMapImage
                        )
                        .frame(width: geo.size.width, height: canvasH)
                        .background(AppTheme.cardBg)

                        // Tap detection layer
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geo.size.width, height: canvasH)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        guard let node = nearestNode(
                                            to: value.location,
                                            in: viewModel.buildingPackage,
                                            canvasSize: canvasSize,
                                            threshold: 36
                                        ) else { return }
                                        switch mapMode {
                                        case .myLocation:
                                            viewModel.selectStartNode(node.id)
                                        case .danger:
                                            activeSheet = .hazardPicker(node)
                                        }
                                    }
                            )

                        // Mode toggle bar (bottom-centre)
                        HStack(spacing: 0) {
                            ModeButton(
                                icon: "person.fill",
                                label: "I'm Here",
                                active: mapMode == .myLocation,
                                color: AppTheme.green
                            ) { mapMode = .myLocation }

                            ModeButton(
                                icon: "exclamationmark.triangle.fill",
                                label: "Danger Here",
                                active: mapMode == .danger,
                                color: AppTheme.red
                            ) { mapMode = .danger }
                        }
                        .background(AppTheme.cardBg2)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 16)

                        // "No map set" hint when no active map
                        if floorPlanVM.activeMapImage == nil {
                            VStack(spacing: 6) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 22))
                                    .foregroundStyle(AppTheme.textDim)
                                Text("No active floor plan")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSec)
                                Text("Import one in the Plans tab and set it as Live")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textDim)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .allowsHitTesting(false)
                        }
                    }
                }

                // Next step banner
                if let route = viewModel.routeResult,
                   let firstStep = route.instructions.first {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.green)
                                .frame(width: 40, height: 40)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(AppTheme.bg)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEXT STEP")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(AppTheme.textSec)
                            Text(firstStep.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textPri)
                                .lineLimit(1)
                            Text(firstStep.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSec)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(AppTheme.cardBg2)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                } else if let failure = viewModel.routeFailureMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.red)
                        Text(failure)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPri)
                        Spacer()
                    }
                    .padding(16)
                    .background(AppTheme.redDim)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.red.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .hazardPicker(let node):
                NodeHazardSheet(node: node)
                    .presentationDetents([.height(380)])
                    .presentationBackground(AppTheme.cardBg)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // Find the node closest to a tap point within `threshold` points.
    private func nearestNode(
        to point: CGPoint,
        in building: BuildingPackage?,
        canvasSize: CGSize,
        threshold: CGFloat
    ) -> Node? {
        guard let building else { return nil }
        var closest: Node?
        var closestDist = threshold
        for node in building.nodes {
            let nodePt = mapNodeToPoint(node.coordinates, in: canvasSize)
            let dist = hypot(nodePt.x - point.x, nodePt.y - point.y)
            if dist < closestDist {
                closestDist = dist
                closest = node
            }
        }
        return closest
    }
}

// MARK: - Canvas floor plan

private struct FloorPlanCanvas: View {
    let building: BuildingPackage?
    let routePath: [Node]
    let activeHazards: [HazardEvent]
    let selectedNodeID: String?
    let canvasSize: CGSize
    let mapImage: UIImage?

    private func pt(_ coords: Coordinates) -> CGPoint {
        mapNodeToPoint(coords, in: canvasSize)
    }

    private var hazardNodeIDs: Set<String> {
        Set(activeHazards.flatMap(\.targetNodeIDs))
    }
    private var hazardEdgeIDs: Set<String> {
        Set(activeHazards.flatMap(\.targetEdgeIDs))
    }
    private var routeNodeIDs: Set<String> { Set(routePath.map(\.id)) }

    private func isOnPath(_ edge: Edge) -> Bool {
        let ids = routePath.map(\.id)
        for i in 0..<max(0, ids.count - 1) {
            if (ids[i] == edge.fromNodeID && ids[i+1] == edge.toNodeID) ||
               (ids[i] == edge.toNodeID   && ids[i+1] == edge.fromNodeID) {
                return true
            }
        }
        return false
    }

    var body: some View {
        ZStack {
            // Building map photo (imported by user) shown as background.
            if let img = mapImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .clipped()
                    .opacity(0.40)
            }

            Canvas { ctx, size in
                guard let building else {
                    let label = Text("Loading map…")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.3))
                    ctx.draw(label, at: CGPoint(x: size.width/2, y: size.height/2))
                    return
                }

                let nodeMap = Dictionary(uniqueKeysWithValues: building.nodes.map { ($0.id, $0) })

                // Building outline (only when no photo)
                let outlineRect = CGRect(
                    x: 28 * 0.4, y: 28 * 0.4,
                    width: size.width - 28 * 0.8,
                    height: size.height - 28 * 0.8
                )
                if mapImage == nil {
                    ctx.fill(Path(outlineRect), with: .color(Color(white: 0.06)))
                }
                ctx.stroke(Path(outlineRect),
                           with: .color(Color(white: 0.18)),
                           style: StrokeStyle(lineWidth: 1.5))

                // Draw edges
                for edge in building.edges {
                    guard let fromNode = nodeMap[edge.fromNodeID],
                          let toNode   = nodeMap[edge.toNodeID] else { continue }

                    let fromPt = pt(fromNode.coordinates)
                    let toPt   = pt(toNode.coordinates)

                    let isPath   = isOnPath(edge)
                    let isHazard = hazardEdgeIDs.contains(edge.id)

                    var edgePath = Path()
                    edgePath.move(to: fromPt)
                    edgePath.addLine(to: toPt)

                    if isPath {
                        ctx.stroke(edgePath,
                                   with: .color(Color(red: 0.22, green: 0.96, blue: 0.29)),
                                   style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 5]))
                    } else if isHazard {
                        ctx.stroke(edgePath,
                                   with: .color(Color(red: 0.90, green: 0.25, blue: 0.25).opacity(0.5)),
                                   style: StrokeStyle(lineWidth: 1.5))
                    } else {
                        ctx.stroke(edgePath,
                                   with: .color(Color(white: mapImage == nil ? 0.25 : 0.55)),
                                   style: StrokeStyle(lineWidth: 1.0))
                    }
                }

                // Draw nodes
                for node in building.nodes {
                    let center = pt(node.coordinates)
                    let isHazard   = hazardNodeIDs.contains(node.id)
                    let isSelected = node.id == selectedNodeID
                    let isOnRoute  = routeNodeIDs.contains(node.id)

                    switch node.type {
                    case .room:
                        let r: CGFloat = 10
                        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 3),
                                 with: .color(isSelected ? Color(red: 0.22, green: 0.96, blue: 0.29).opacity(0.2)
                                              : Color(white: mapImage == nil ? 0.15 : 0.0).opacity(0.6)))
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 3),
                                   with: .color(isSelected ? Color(red: 0.22, green: 0.96, blue: 0.29)
                                                : Color(white: mapImage == nil ? 0.30 : 0.70)),
                                   lineWidth: 1.2)

                    case .exit:
                        let s: CGFloat = 10
                        let diamond = Path { p in
                            p.move(to:    CGPoint(x: center.x,     y: center.y - s))
                            p.addLine(to: CGPoint(x: center.x + s, y: center.y))
                            p.addLine(to: CGPoint(x: center.x,     y: center.y + s))
                            p.addLine(to: CGPoint(x: center.x - s, y: center.y))
                            p.closeSubpath()
                        }
                        let exitColor = isHazard
                            ? Color(red: 0.90, green: 0.25, blue: 0.25)
                            : Color(red: 0.22, green: 0.96, blue: 0.29)
                        ctx.fill(diamond, with: .color(exitColor.opacity(0.25)))
                        ctx.stroke(diamond, with: .color(exitColor), lineWidth: 1.5)

                    case .refugePoint:
                        let r: CGFloat = 9
                        let circle = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                             width: r * 2, height: r * 2))
                        ctx.fill(circle, with: .color(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.2)))
                        ctx.stroke(circle, with: .color(Color(red: 0.96, green: 0.62, blue: 0.04)), lineWidth: 1.5)

                    case .stairwell:
                        let r: CGFloat = 7
                        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        ctx.fill(Path(rect), with: .color(Color(white: 0.18)))
                        ctx.stroke(Path(rect), with: .color(Color(white: 0.40)), lineWidth: 1)

                    case .intersection:
                        let r: CGFloat = 3
                        let dot = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                          width: r * 2, height: r * 2))
                        ctx.fill(dot, with: .color(Color(white: 0.35)))

                    case .lift:
                        let r: CGFloat = 6
                        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2),
                                   with: .color(Color(white: 0.30)), lineWidth: 1)
                    }

                    // Hazard ring
                    if isHazard {
                        let hr: CGFloat = 16
                        let ring = Path(ellipseIn: CGRect(x: center.x - hr, y: center.y - hr,
                                                          width: hr * 2, height: hr * 2))
                        ctx.stroke(ring, with: .color(Color(red: 0.90, green: 0.25, blue: 0.25).opacity(0.6)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }

                    // Selected — user location pin
                    if isSelected {
                        let pr: CGFloat = 14
                        let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                           width: pr * 2, height: pr * 2))
                        ctx.fill(pulse, with: .color(Color(red: 0.22, green: 0.96, blue: 0.29).opacity(0.25)))
                        ctx.stroke(pulse, with: .color(Color(red: 0.22, green: 0.96, blue: 0.29)), lineWidth: 2)

                        // Dot in centre
                        let dr: CGFloat = 5
                        let dot = Path(ellipseIn: CGRect(x: center.x - dr, y: center.y - dr,
                                                         width: dr * 2, height: dr * 2))
                        ctx.fill(dot, with: .color(Color(red: 0.22, green: 0.96, blue: 0.29)))

                        // "YOU" label above
                        let youLabel = Text("YOU")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 0.22, green: 0.96, blue: 0.29))
                        ctx.draw(youLabel, at: CGPoint(x: center.x, y: center.y - 24))
                    }

                    // Node labels
                    if node.type == .room || node.type == .exit || node.type == .refugePoint {
                        let label = Text(node.name)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Color(white: mapImage == nil ? 0.55 : 0.90))
                        ctx.draw(label, at: CGPoint(x: center.x, y: center.y + 16))
                    }
                }

                // Hazard labels
                for hazard in activeHazards {
                    for nodeID in hazard.targetNodeIDs {
                        guard let node = nodeMap[nodeID] else { continue }
                        let center = pt(node.coordinates)
                        let label = Text(hazard.title.uppercased().prefix(6))
                            .font(.system(size: 7, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 0.90, green: 0.25, blue: 0.25))
                        ctx.draw(label, at: CGPoint(x: center.x, y: center.y - 22))
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Node hazard sheet (tap-to-place)

private struct NodeHazardSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let node: Node

    private var existingHazards: [HazardEvent] {
        viewModel.activeHazards.filter { $0.targetNodeIDs.contains(node.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SET HAZARD")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.textSec)
                    Text(node.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(AppTheme.textPri)
                    Text(node.type.rawValue.capitalized + " · Floor \(node.floor.capitalized)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.textDim)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider().background(AppTheme.divider)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if !existingHazards.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVE HAZARDS HERE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(AppTheme.red)

                            ForEach(existingHazards) { hazard in
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(AppTheme.red)
                                    Text(hazard.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.textPri)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        viewModel.clearAdHocHazards(nodeID: node.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(AppTheme.textDim)
                                    }
                                }
                                .padding(12)
                                .background(AppTheme.redDim)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.red.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.top, 16)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MARK AS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.top, existingHazards.isEmpty ? 16 : 8)

                        ForEach(HazardSeverity.allCases, id: \.self) { severity in
                            Button {
                                viewModel.placeAdHocHazard(nodeID: node.id, severity: severity)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(severity.accentColor.opacity(0.15))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: severity.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(severity.accentColor)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(severity.displayTitle.uppercased())
                                            .font(.system(size: 14, weight: .black, design: .monospaced))
                                            .tracking(1)
                                            .foregroundStyle(AppTheme.textPri)
                                        Text(severity.detailText)
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.textSec)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppTheme.textDim)
                                }
                                .padding(14)
                                .background(AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.border, lineWidth: 1))
                            }
                        }
                    }

                    if !existingHazards.isEmpty {
                        Button {
                            viewModel.clearAdHocHazards(nodeID: node.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Clear all hazards at this location")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(AppTheme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.redDim)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.red.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Mode toggle button

private struct ModeButton: View {
    let icon: String
    let label: String
    let active: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(active ? color : AppTheme.textDim)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(active ? color.opacity(0.15) : Color.clear)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    LiveMapView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .environmentObject(FloorPlanLibraryViewModel())
}
