import SwiftUI

// MARK: - Coordinate mapper (matches LiveMapView)

private func mapNodeToPoint(_ coords: Coordinates, in canvasSize: CGSize) -> CGPoint {
    let minX = 2.0, maxX = 63.0, minY = 1.0, maxY = 29.0, padding = 20.0
    let usableW = canvasSize.width  - padding * 2
    let usableH = canvasSize.height - padding * 2
    let x = padding + ((coords.x - minX) / (maxX - minX)) * usableW
    let y = padding + ((coords.y - minY) / (maxY - minY)) * usableH
    return CGPoint(x: x, y: y)
}

// MARK: - ReportHazardView

struct ReportHazardView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var floorPlanVM: FloorPlanLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ReportHazardType? = nil
    @State private var selectedHazardNodeID: String? = nil
    @State private var notes = ""
    @State private var submitted = false

    private var selectedNode: Node? {
        guard let id = selectedHazardNodeID, let building = viewModel.buildingPackage else { return nil }
        return building.node(id: id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("REPORT HAZARD")
                    .font(.system(size: 16, weight: .black))
                    .tracking(1)
                    .foregroundStyle(AppTheme.textPri)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.cardBg2)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            if submitted {
                submittedState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        locationSection
                        hazardTypeSection
                        notesSection
                        submitSection

                        Text("MISUSE OF EMERGENCY REPORTING IS A SAFETY VIOLATION.\nALL REPORTS ARE LOGGED WITH YOUR LOCATION.")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundStyle(AppTheme.textDim)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            if selectedHazardNodeID == nil {
                selectedHazardNodeID = viewModel.selectedStartNodeID
            }
        }
    }

    // MARK: - Location Section (Interactive Mini Map)

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(AppTheme.red)
                Text("HAZARD LOCATION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
                Spacer()
                if let node = selectedNode {
                    Text(node.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.redDim)
                        .clipShape(Capsule())
                }
            }

            // Interactive mini map
            GeometryReader { geo in
                let canvasSize = CGSize(width: geo.size.width, height: 220)

                ZStack {
                    // Floor plan background
                    if let img = floorPlanVM.activeMapImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: canvasSize.width, height: canvasSize.height)
                            .clipped()
                            .opacity(0.35)
                    }

                    // Canvas drawing layer
                    Canvas { ctx, size in
                        guard let building = viewModel.buildingPackage else { return }

                        let nodeMap = Dictionary(uniqueKeysWithValues: building.nodes.map { ($0.id, $0) })

                        // Building outline
                        let outlineRect = CGRect(
                            x: 20 * 0.4, y: 20 * 0.4,
                            width: size.width - 20 * 0.8,
                            height: size.height - 20 * 0.8
                        )
                        if floorPlanVM.activeMapImage == nil {
                            ctx.fill(Path(outlineRect), with: .color(Color(white: 0.06)))
                        }
                        ctx.stroke(Path(outlineRect),
                                   with: .color(Color(white: 0.18)),
                                   style: StrokeStyle(lineWidth: 1))

                        // Edges
                        for edge in building.edges {
                            guard let fromNode = nodeMap[edge.fromNodeID],
                                  let toNode = nodeMap[edge.toNodeID] else { continue }

                            let fromPt = mapNodeToPoint(fromNode.coordinates, in: canvasSize)
                            let toPt = mapNodeToPoint(toNode.coordinates, in: canvasSize)

                            var edgePath = Path()
                            edgePath.move(to: fromPt)
                            edgePath.addLine(to: toPt)

                            ctx.stroke(edgePath,
                                       with: .color(Color(white: floorPlanVM.activeMapImage == nil ? 0.22 : 0.50)),
                                       style: StrokeStyle(lineWidth: 0.8))
                        }

                        // Nodes
                        for node in building.nodes {
                            let center = mapNodeToPoint(node.coordinates, in: canvasSize)
                            let isSelected = node.id == selectedHazardNodeID

                            switch node.type {
                            case .room:
                                let r: CGFloat = 8
                                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                                ctx.fill(Path(roundedRect: rect, cornerRadius: 2),
                                         with: .color(isSelected
                                                      ? AppTheme.red.opacity(0.25)
                                                      : Color(white: floorPlanVM.activeMapImage == nil ? 0.12 : 0.0).opacity(0.5)))
                                ctx.stroke(Path(roundedRect: rect, cornerRadius: 2),
                                           with: .color(isSelected ? AppTheme.red : Color(white: 0.35)),
                                           lineWidth: isSelected ? 1.5 : 0.8)

                            case .exit:
                                let s: CGFloat = 8
                                let diamond = Path { p in
                                    p.move(to:    CGPoint(x: center.x,     y: center.y - s))
                                    p.addLine(to: CGPoint(x: center.x + s, y: center.y))
                                    p.addLine(to: CGPoint(x: center.x,     y: center.y + s))
                                    p.addLine(to: CGPoint(x: center.x - s, y: center.y))
                                    p.closeSubpath()
                                }
                                let exitColor = isSelected ? AppTheme.red : AppTheme.green
                                ctx.fill(diamond, with: .color(exitColor.opacity(0.2)))
                                ctx.stroke(diamond, with: .color(exitColor), lineWidth: 1.2)

                            case .refugePoint:
                                let r: CGFloat = 7
                                let circle = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                                     width: r * 2, height: r * 2))
                                ctx.fill(circle, with: .color(AppTheme.amber.opacity(0.15)))
                                ctx.stroke(circle, with: .color(AppTheme.amber), lineWidth: 1.2)

                            case .stairwell:
                                let r: CGFloat = 6
                                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                                ctx.fill(Path(rect), with: .color(Color(white: 0.15)))
                                ctx.stroke(Path(rect), with: .color(Color(white: 0.35)), lineWidth: 0.8)

                            case .intersection:
                                let r: CGFloat = 2.5
                                let dot = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                                  width: r * 2, height: r * 2))
                                ctx.fill(dot, with: .color(Color(white: 0.30)))

                            case .lift:
                                let r: CGFloat = 5
                                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                                ctx.stroke(Path(roundedRect: rect, cornerRadius: 2),
                                           with: .color(Color(white: 0.28)), lineWidth: 0.8)
                            }

                            // Selected node — red pulse ring + pin
                            if isSelected {
                                let pr: CGFloat = 14
                                let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                                    width: pr * 2, height: pr * 2))
                                ctx.fill(pulse, with: .color(AppTheme.red.opacity(0.20)))
                                ctx.stroke(pulse, with: .color(AppTheme.red), lineWidth: 2)

                                let dr: CGFloat = 4
                                let dot = Path(ellipseIn: CGRect(x: center.x - dr, y: center.y - dr,
                                                                  width: dr * 2, height: dr * 2))
                                ctx.fill(dot, with: .color(AppTheme.red))

                                let pinLabel = Text("HAZARD")
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundStyle(AppTheme.red)
                                ctx.draw(pinLabel, at: CGPoint(x: center.x, y: center.y - 20))
                            }

                            // Node labels for rooms, exits, refuge points
                            if node.type == .room || node.type == .exit || node.type == .refugePoint {
                                let label = Text(node.name)
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundStyle(Color(white: floorPlanVM.activeMapImage == nil ? 0.50 : 0.85))
                                ctx.draw(label, at: CGPoint(x: center.x, y: center.y + 14))
                            }
                        }
                    }
                    .allowsHitTesting(false)

                    // Tap detection overlay
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    guard let node = nearestNode(
                                        to: value.location,
                                        canvasSize: canvasSize,
                                        threshold: 30
                                    ) else { return }
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedHazardNodeID = node.id
                                    }
                                }
                        )
                }
                .frame(height: 220)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectedHazardNodeID != nil ? AppTheme.red.opacity(0.3) : AppTheme.border,
                                lineWidth: 1)
                )
            }
            .frame(height: 220)

            // Hint text
            Text("TAP A NODE ON THE MAP TO SET HAZARD LOCATION")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    // MARK: - Hazard Type

    private var hazardTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HAZARD TYPE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ReportHazardType.allCases) { type in
                    Button { selectedType = type } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(selectedType == type ? AppTheme.bg : type.color)
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(selectedType == type ? AppTheme.bg : AppTheme.textSec)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedType == type ? type.color : AppTheme.cardBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedType == type ? type.color : AppTheme.border, lineWidth: 1)
                        )
                        .overlay(alignment: .topTrailing) {
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppTheme.bg)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADDITIONAL NOTES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBg2)
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                if notes.isEmpty {
                    Text("Briefly describe the situation (e.g., 'Blocked exit', 'Electrical sparks')")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textDim)
                        .padding(14)
                }
                TextEditor(text: $notes)
                    .foregroundStyle(AppTheme.textPri)
                    .font(.system(size: 13))
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(height: 90)
            }
        }
    }

    // MARK: - Submit

    private var submitSection: some View {
        let canSubmit = selectedType != nil && selectedHazardNodeID != nil

        return Button {
            guard let type = selectedType else { return }
            submitReport(type: type)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                Text("SUBMIT REPORT")
                    .font(.system(size: 15, weight: .black))
                    .tracking(1)
            }
            .foregroundStyle(canSubmit ? AppTheme.textPri : AppTheme.textDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canSubmit ? AppTheme.red : AppTheme.cardBg2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(canSubmit ? AppTheme.red.opacity(0.5) : AppTheme.border, lineWidth: 1)
            )
        }
        .disabled(!canSubmit)
    }

    // MARK: - Submitted State

    private var submittedState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.green)
            Text("Report Submitted")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AppTheme.textPri)

            if let node = selectedNode {
                Text("Hazard reported at **\(node.name)**.\nThe routing engine is recalculating safe paths.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
            } else {
                Text("Your hazard report has been logged.\nThe routing engine is recalculating safe paths.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func nearestNode(to point: CGPoint, canvasSize: CGSize, threshold: CGFloat) -> Node? {
        guard let building = viewModel.buildingPackage else { return nil }
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

    // MARK: - Submit logic

    private func submitReport(type: ReportHazardType) {
        guard let nodeID = selectedHazardNodeID else { return }

        // Place ad-hoc hazard at the selected node with severity based on type
        viewModel.placeAdHocHazard(nodeID: nodeID, severity: type.severity)

        withAnimation { submitted = true }
    }
}

// MARK: - Hazard type model

enum ReportHazardType: String, CaseIterable, Identifiable {
    case fire   = "FIRE"
    case smoke  = "SMOKE"
    case debris = "DEBRIS"
    case other  = "OTHER"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fire:   return "flame.fill"
        case .smoke:  return "smoke.fill"
        case .debris: return "xmark.app.fill"
        case .other:  return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .fire:   return Color(red: 1.0, green: 0.35, blue: 0.15)
        case .smoke:  return Color(white: 0.55)
        case .debris: return AppTheme.amber
        case .other:  return AppTheme.red
        }
    }

    var severity: HazardSeverity {
        switch self {
        case .fire:   return .blocked
        case .smoke:  return .highRisk
        case .debris: return .blocked
        case .other:  return .highRisk
        }
    }
}

#Preview {
    ReportHazardView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .environmentObject(FloorPlanLibraryViewModel())
}
