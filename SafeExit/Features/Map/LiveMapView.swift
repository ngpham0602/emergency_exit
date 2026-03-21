import SwiftUI

struct LiveMapView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showLocationPicker = false

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
                    ZStack(alignment: .bottomLeading) {
                        // Floor plan
                        FloorPlanCanvas(
                            building: viewModel.buildingPackage,
                            routePath: viewModel.routeResult?.path ?? [],
                            activeHazards: viewModel.activeHazards,
                            selectedNodeID: viewModel.selectedStartNodeID,
                            canvasSize: CGSize(width: geo.size.width, height: geo.size.height - 90)
                        )
                        .frame(width: geo.size.width, height: geo.size.height - 90)
                        .background(AppTheme.cardBg)

                        // Map controls (right side)
                        VStack(spacing: 8) {
                            MapControlButton(icon: "location.fill") {}
                            MapControlButton(icon: "arrow.up.left.and.down.right.magnifyingglass") {}
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)

                        // Location selector button (bottom-left)
                        Button { showLocationPicker = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(AppTheme.green)
                                Text(viewModel.currentStartNode?.name ?? "Select Location")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.cardBg2)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
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
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet()
                .presentationDetents([.fraction(0.45)])
                .presentationBackground(AppTheme.cardBg)
        }
    }
}

// MARK: - Canvas floor plan

private struct FloorPlanCanvas: View {
    let building: BuildingPackage?
    let routePath: [Node]
    let activeHazards: [HazardEvent]
    let selectedNodeID: String?
    let canvasSize: CGSize

    // Coordinate space from JSON: x 4..60, y 4..26
    private let minX = 2.0, maxX = 63.0
    private let minY = 1.0, maxY = 29.0
    private let padding = 28.0

    private func pt(_ coords: Coordinates) -> CGPoint {
        let usableW = canvasSize.width  - padding * 2
        let usableH = canvasSize.height - padding * 2
        let x = padding + ((coords.x - minX) / (maxX - minX)) * usableW
        let y = padding + ((coords.y - minY) / (maxY - minY)) * usableH
        return CGPoint(x: x, y: y)
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
        Canvas { ctx, size in
            guard let building else {
                // Empty state
                let label = Text("Loading map…")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.3))
                ctx.draw(label, at: CGPoint(x: size.width/2, y: size.height/2))
                return
            }

            let nodeMap = Dictionary(uniqueKeysWithValues: building.nodes.map { ($0.id, $0) })

            // --- Building outline ---
            let outlineRect = CGRect(
                x: padding * 0.4, y: padding * 0.4,
                width: size.width - padding * 0.8,
                height: size.height - padding * 0.8
            )
            ctx.fill(Path(outlineRect), with: .color(Color(white: 0.06)))
            ctx.stroke(Path(outlineRect),
                       with: .color(Color(white: 0.18)),
                       style: StrokeStyle(lineWidth: 1.5))

            // --- Draw edges ---
            for edge in building.edges {
                guard let fromNode = nodeMap[edge.fromNodeID],
                      let toNode   = nodeMap[edge.toNodeID] else { continue }

                let fromPt = pt(fromNode.coordinates)
                let toPt   = pt(toNode.coordinates)

                let isPath    = isOnPath(edge)
                let isHazard  = hazardEdgeIDs.contains(edge.id)

                var edgePath = Path()
                edgePath.move(to: fromPt)
                edgePath.addLine(to: toPt)

                if isPath {
                    ctx.stroke(edgePath,
                               with: .color(Color(red: 0.22, green: 0.96, blue: 0.29)),
                               style: StrokeStyle(
                                lineWidth: 2.5,
                                lineCap: .round,
                                dash: [7, 5]))
                } else if isHazard {
                    ctx.stroke(edgePath,
                               with: .color(Color(red: 0.90, green: 0.25, blue: 0.25).opacity(0.5)),
                               style: StrokeStyle(lineWidth: 1.5))
                } else {
                    ctx.stroke(edgePath,
                               with: .color(Color(white: 0.25)),
                               style: StrokeStyle(lineWidth: 1.0))
                }
            }

            // --- Draw nodes ---
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
                                          : Color(white: 0.15)))
                    ctx.stroke(Path(roundedRect: rect, cornerRadius: 3),
                               with: .color(isSelected ? Color(red: 0.22, green: 0.96, blue: 0.29)
                                            : Color(white: 0.30)),
                               lineWidth: 1.2)

                case .exit:
                    let size: CGFloat = 10
                    let diamond = Path { p in
                        p.move(to:    CGPoint(x: center.x,        y: center.y - size))
                        p.addLine(to: CGPoint(x: center.x + size, y: center.y))
                        p.addLine(to: CGPoint(x: center.x,        y: center.y + size))
                        p.addLine(to: CGPoint(x: center.x - size, y: center.y))
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

                // Selected pulse ring
                if isSelected {
                    let pr: CGFloat = 14
                    let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                       width: pr * 2, height: pr * 2))
                    ctx.fill(pulse, with: .color(Color(red: 0.22, green: 0.96, blue: 0.29).opacity(0.15)))
                }

                // Node labels for rooms and exits
                if node.type == .room || node.type == .exit || node.type == .refugePoint {
                    let label = Text(node.name)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color(white: 0.55))
                    ctx.draw(label, at: CGPoint(x: center.x, y: center.y + 16))
                }
            }

            // --- Hazard labels ---
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
    }
}

// MARK: - Location picker sheet

private struct LocationPickerSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Select Your Location")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPri)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textDim)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().background(AppTheme.divider)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.roomNodes) { node in
                        Button {
                            viewModel.selectStartNode(node.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "square.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(
                                        viewModel.selectedStartNodeID == node.id
                                            ? AppTheme.green : AppTheme.textDim)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppTheme.textPri)
                                    Text("Floor: \(node.floor.capitalized)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.textSec)
                                }

                                Spacer()

                                if viewModel.selectedStartNodeID == node.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.green)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        Divider().background(AppTheme.divider).padding(.leading, 52)
                    }
                }
            }
        }
    }
}

// MARK: - Map control button

private struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSec)
                .frame(width: 36, height: 36)
                .background(AppTheme.cardBg2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
        }
    }
}

#Preview {
    LiveMapView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
