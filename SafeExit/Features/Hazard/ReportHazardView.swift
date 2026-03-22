import SwiftUI

// MARK: - ReportHazardView

struct ReportHazardView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var floorPlanVM: FloorPlanLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ReportHazardType? = nil
    @State private var selectedHazardNodeID: String? = nil
    @State private var notes = ""
    @State private var submitted = false

    // Firestore nodes
    @State private var firestoreNodes: [CustomNode] = []
    @State private var isLoadingNodes = false
    @State private var loadError: String? = nil

    // Zoom & pan
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero

    private var isZoomed: Bool { scale != 1.0 || panOffset != .zero }

    private var selectedCustomNode: CustomNode? {
        firestoreNodes.first(where: { $0.id == selectedHazardNodeID })
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
        .task {
            await loadFirestoreNodes()
        }
    }

    // MARK: - Load nodes from Firestore

    private func loadFirestoreNodes() async {
        let mapID = floorPlanVM.activeMapID ?? "default"
        isLoadingNodes = true
        loadError = nil
        do {
            let nodes = try await FirestoreService.shared.fetchCustomNodes(mapID: mapID)
            firestoreNodes = nodes
            // Default selection: first node, or none
            if selectedHazardNodeID == nil, let first = nodes.first {
                selectedHazardNodeID = first.id
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingNodes = false
    }

    // MARK: - Location Section (Interactive Mini Map with Firestore nodes + Zoom/Pan)

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

                if isLoadingNodes {
                    ProgressView()
                        .tint(AppTheme.textSec)
                        .scaleEffect(0.7)
                } else if let node = selectedCustomNode {
                    Text(node.label.isEmpty ? node.id.prefix(6).description : node.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.redDim)
                        .clipShape(Capsule())
                }
            }

            // Interactive mini map with zoom/pan
            GeometryReader { geo in
                let canvasSize = CGSize(width: geo.size.width, height: 260)

                ZStack {
                    // ── Layer 1: transformed content (floor plan + nodes) ──
                    ZStack {
                        // Floor plan background
                        if let img = floorPlanVM.activeMapImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: canvasSize.width, height: canvasSize.height)
                                .clipped()
                                .opacity(0.65)
                        } else {
                            AppTheme.cardBg
                        }

                        // Canvas: draw Firestore nodes + edges
                        Canvas { ctx, size in
                            drawFirestoreGraph(ctx: &ctx, size: size)
                        }
                    }
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .scaleEffect(scale, anchor: .center)
                    .offset(panOffset)
                    .allowsHitTesting(false)

                    // ── Layer 2: gesture overlay ──
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(max(lastScale * value, 1.0), 5.0)
                                    }
                                    .onEnded { _ in lastScale = scale },
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let d = hypot(value.translation.width,
                                                      value.translation.height)
                                        if d > 8 {
                                            panOffset = CGSize(
                                                width:  lastPanOffset.width  + value.translation.width,
                                                height: lastPanOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { value in
                                        let d = hypot(value.translation.width,
                                                      value.translation.height)
                                        if d < 8 {
                                            let canvasPt = screenToCanvas(
                                                value.startLocation, in: canvasSize)
                                            handleNodeTap(canvasPt, in: canvasSize)
                                        } else {
                                            lastPanOffset = panOffset
                                        }
                                    }
                            )
                        )

                    // ── Layer 3: fixed UI overlays (zoom badge, reset button) ──
                    VStack {
                        HStack {
                            Spacer()
                            // Zoom indicator + reset
                            if isZoomed {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        scale = 1.0; lastScale = 1.0
                                        panOffset = .zero; lastPanOffset = .zero
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                                            .font(.system(size: 9, weight: .bold))
                                        Text(String(format: "%.1f×", scale))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundStyle(AppTheme.amber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.cardBg2.opacity(0.9))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(AppTheme.amber.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                        .padding(8)
                        Spacer()

                        // Node count badge
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(firestoreNodes.isEmpty ? AppTheme.red : AppTheme.green)
                                    .frame(width: 6, height: 6)
                                Text(firestoreNodes.isEmpty
                                     ? "NO NODES"
                                     : "\(firestoreNodes.count) NODES")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.cardBg2.opacity(0.85))
                            .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .frame(height: 260)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectedHazardNodeID != nil
                                ? AppTheme.red.opacity(0.3) : AppTheme.border,
                                lineWidth: 1)
                )
            }
            .frame(height: 260)

            // Hint / error text
            if let err = loadError {
                Text("FAILED TO LOAD NODES: \(err.uppercased())")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.red)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            } else {
                Text("PINCH TO ZOOM · TAP A NODE TO SET HAZARD LOCATION")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Draw Firestore nodes on Canvas

    private func drawFirestoreGraph(ctx: inout GraphicsContext, size: CGSize) {
        guard !firestoreNodes.isEmpty else {
            let label = Text(isLoadingNodes ? "Loading nodes…" : "No nodes found")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.3))
            ctx.draw(label, at: CGPoint(x: size.width / 2, y: size.height / 2))
            return
        }

        let _ = Dictionary(uniqueKeysWithValues: firestoreNodes.map { ($0.id, $0) })

        // Auto-connect nearby nodes (same proximity logic as MapEditorView)
        let threshold: Double = 0.13
        for i in 0..<firestoreNodes.count {
            for j in (i + 1)..<firestoreNodes.count {
                let ni = firestoreNodes[i], nj = firestoreNodes[j]
                let d = hypot(ni.nx - nj.nx, ni.ny - nj.ny)
                guard d <= threshold else { continue }

                let a = CGPoint(x: CGFloat(ni.nx) * size.width,
                                y: CGFloat(ni.ny) * size.height)
                let b = CGPoint(x: CGFloat(nj.nx) * size.width,
                                y: CGFloat(nj.ny) * size.height)

                var line = Path()
                line.move(to: a)
                line.addLine(to: b)

                let edgeDanger = ni.isDanger || nj.isDanger
                ctx.stroke(line,
                           with: .color(edgeDanger
                                        ? AppTheme.red.opacity(0.35)
                                        : Color(white: 0.30).opacity(0.5)),
                           style: StrokeStyle(lineWidth: 0.5))
            }
        }

        // Draw nodes
        for node in firestoreNodes {
            let center = CGPoint(x: CGFloat(node.nx) * size.width,
                                 y: CGFloat(node.ny) * size.height)
            let isSelected = node.id == selectedHazardNodeID

            let darkFill = Color(white: 0.18)

            if node.isExit {
                // Amber diamond for exits
                let s: CGFloat = 6
                let diamond = Path { p in
                    p.move(to:    CGPoint(x: center.x,     y: center.y - s))
                    p.addLine(to: CGPoint(x: center.x + s, y: center.y))
                    p.addLine(to: CGPoint(x: center.x,     y: center.y + s))
                    p.addLine(to: CGPoint(x: center.x - s, y: center.y))
                    p.closeSubpath()
                }
                let exitColor = node.isDanger ? AppTheme.red : AppTheme.amber
                ctx.fill(diamond, with: .color(exitColor.opacity(0.85)))
                ctx.stroke(diamond, with: .color(exitColor), lineWidth: 1)

                let exitLabel = Text("EXIT")
                    .font(.system(size: 5, weight: .black, design: .monospaced))
                    .foregroundStyle(AppTheme.red)
                ctx.draw(exitLabel, at: CGPoint(x: center.x, y: center.y + 12))
            } else {
                // Dark circle with red ring for regular nodes
                let r: CGFloat = 6
                let circle = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                     width: r * 2, height: r * 2))
                ctx.fill(circle, with: .color(darkFill.opacity(0.85)))
                ctx.stroke(circle,
                           with: .color(isSelected ? AppTheme.green
                                        : (node.isDanger ? AppTheme.red : AppTheme.red.opacity(0.8))),
                           style: StrokeStyle(lineWidth: isSelected ? 1.5 : 1))
            }

            // Danger warning triangle
            if node.isDanger {
                let triSize: CGFloat = 4
                let triY = center.y - 9
                let triangle = Path { p in
                    p.move(to:    CGPoint(x: center.x,           y: triY - triSize))
                    p.addLine(to: CGPoint(x: center.x + triSize, y: triY + triSize * 0.6))
                    p.addLine(to: CGPoint(x: center.x - triSize, y: triY + triSize * 0.6))
                    p.closeSubpath()
                }
                ctx.fill(triangle, with: .color(Color.white.opacity(0.9)))
                ctx.stroke(triangle, with: .color(AppTheme.red), lineWidth: 0.8)
            }

            // Selected: green pulse ring
            if isSelected {
                let pr: CGFloat = 9
                let pulse = Path(ellipseIn: CGRect(x: center.x - pr, y: center.y - pr,
                                                    width: pr * 2, height: pr * 2))
                ctx.fill(pulse, with: .color(AppTheme.green.opacity(0.20)))
                ctx.stroke(pulse, with: .color(AppTheme.green), lineWidth: 1.5)

                let dr: CGFloat = 3
                let dot = Path(ellipseIn: CGRect(x: center.x - dr, y: center.y - dr,
                                                  width: dr * 2, height: dr * 2))
                ctx.fill(dot, with: .color(AppTheme.green))
            }

            // Node label
            let label = Text(node.label.isEmpty ? "N?" : node.label)
                .font(.system(size: 5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
            ctx.draw(label, at: CGPoint(x: center.x,
                                        y: center.y + (node.isExit ? 16 : 11)))
        }
    }

    // MARK: - Coordinate conversion (screen → canvas accounting for zoom/pan)

    private func screenToCanvas(_ pt: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (pt.x - panOffset.width  - size.width  / 2) / scale + size.width  / 2,
            y: (pt.y - panOffset.height - size.height / 2) / scale + size.height / 2
        )
    }

    private func handleNodeTap(_ pt: CGPoint, in size: CGSize) {
        let threshold: CGFloat = 28 / scale
        guard let nearest = nearestCustomNode(to: pt, in: size, threshold: threshold) else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedHazardNodeID = nearest.id
        }
    }

    private func nearestCustomNode(to pt: CGPoint, in size: CGSize,
                                    threshold: CGFloat) -> CustomNode? {
        var closest: CustomNode?
        var closestDist = threshold
        for node in firestoreNodes {
            let nodePt = CGPoint(x: CGFloat(node.nx) * size.width,
                                 y: CGFloat(node.ny) * size.height)
            let dist = hypot(nodePt.x - pt.x, nodePt.y - pt.y)
            if dist < closestDist {
                closestDist = dist
                closest = node
            }
        }
        return closest
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

            if let node = selectedCustomNode {
                let name = node.label.isEmpty ? "Node \(node.id.prefix(6))" : node.label
                Text("Hazard reported at **\(name)**.\nThe routing engine is recalculating safe paths.")
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

    // MARK: - Submit logic

    private func submitReport(type: ReportHazardType) {
        guard let nodeID = selectedHazardNodeID else { return }

        // If the selected node maps to a BuildingPackage node, place ad-hoc hazard
        if let _ = viewModel.buildingPackage?.node(id: nodeID) {
            viewModel.placeAdHocHazard(nodeID: nodeID, severity: type.severity)
        }

        // Also report to Firestore for persistence
        if let node = selectedCustomNode {
            let hazard = Hazard(
                buildingId: "",
                floorId: "",
                type: type.rawValue.lowercased(),
                xPercent: node.nx,
                yPercent: node.ny,
                confidence: 1.0,
                confirmations: 1,
                reportedBy: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(600)
            )
            Task {
                try? await FirestoreService.shared.reportHazard(hazard)
            }
        }

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
