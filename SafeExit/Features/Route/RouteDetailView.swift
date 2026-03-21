import SwiftUI

struct RouteDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showReportHazard = false

    private var isRerouted: Bool {
        // Rerouted when any blocked hazard is active and route changed to refuge/side exit
        viewModel.activeHazards.contains { $0.severity == .blocked }
    }

    private var remainingSteps: [RouteInstruction] {
        guard let instructions = viewModel.routeResult?.instructions else { return [] }
        return Array(instructions.dropFirst())
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Route Detail")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPri)
                    Spacer()
                    Menu {
                        Button("Reset All Hazards", role: .destructive) {
                            viewModel.resetHazards()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // Path blockage banner (rerouted)
                        if isRerouted {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.red)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Path Blockage Detected")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(AppTheme.red)
                                    Text(viewModel.activeHazards.first?.title ?? "Rerouting to alternate path…")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.textSec)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button("DISMISS") {
                                    viewModel.resetHazards()
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.red)
                            }
                            .padding(14)
                            .background(AppTheme.redDim)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.red.opacity(0.3), lineWidth: 1))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Next instruction card
                        if let route = viewModel.routeResult,
                           let first = route.instructions.first {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("NEXT INSTRUCTION")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .tracking(2)
                                        .foregroundStyle(AppTheme.textSec)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppTheme.green)
                                            .frame(width: 6, height: 6)
                                        Text("ETA \(timeAgoString())")
                                            .font(.system(size: 10))
                                            .foregroundStyle(AppTheme.green)
                                    }
                                }

                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.green)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: instructionIcon(for: first.title))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(AppTheme.bg)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(first.title)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(AppTheme.textPri)
                                        Text(first.detail)
                                            .font(.system(size: 13))
                                            .foregroundStyle(AppTheme.textSec)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                HStack(spacing: 16) {
                                    Label("Live Path", systemImage: "dot.radiowaves.up.forward")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.green)
                                    Label("ALL CLEAR", systemImage: "checkmark.shield.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.textSec)
                                }
                                .padding(.top, 4)

                                // Distance badge
                                HStack {
                                    Spacer()
                                    Text("\(Int(route.totalDistance))m")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundStyle(AppTheme.bg)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(AppTheme.green)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(16)
                            .background(AppTheme.greenDim)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.green.opacity(0.25), lineWidth: 1))
                        } else if let failure = viewModel.routeFailureMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundStyle(AppTheme.red)
                                Text(failure)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.redDim)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Remaining steps
                        if !remainingSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("REMAINING STEPS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.textSec)
                                    .padding(.horizontal, 2)

                                ForEach(Array(remainingSteps.enumerated()), id: \.element.id) { idx, step in
                                    HStack(alignment: .top, spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.cardBg3)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: stepIcon(for: idx))
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(AppTheme.textSec)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(step.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AppTheme.textPri)
                                                Spacer()
                                                Text(estimatedTime(for: idx + 1))
                                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                    .foregroundStyle(AppTheme.textSec)
                                            }
                                            Text(step.detail)
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppTheme.textSec)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .padding(14)
                                    .background(AppTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        // Alternative paths
                        if let route = viewModel.routeResult {
                            alternativePathsSection(route: route)
                        }

                        // Report hazard button
                        Button { showReportHazard = true } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                Text("REPORT NEW HAZARD")
                                    .font(.system(size: 15, weight: .black))
                                    .tracking(1)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                        // Hazard control toggles (admin panel integrated)
                        if let building = viewModel.buildingPackage, !building.hazardTemplates.isEmpty {
                            hazardSimulationSection(building: building)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showReportHazard) {
            ReportHazardView()
                .presentationBackground(AppTheme.cardBg)
        }
        .animation(.easeInOut(duration: 0.3), value: isRerouted)
    }

    private func alternativePathsSection(route: RouteResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALTERNATIVE PATHS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AltPathCard(
                        label: "ROUTE BETA",
                        safePercent: route.destinationKind == .exit ? 94 : 78,
                        time: estimatedTotalTime(distance: route.totalDistance),
                        isActive: true
                    )
                    AltPathCard(
                        label: route.destinationKind == .refugePoint ? "REFUGE POINT" : "ROOF EVAC",
                        safePercent: 88,
                        time: estimatedTotalTime(distance: route.totalDistance * 1.4),
                        isActive: false
                    )
                    AltPathCard(label: "CAMPUS EXIT", safePercent: 72,
                               time: estimatedTotalTime(distance: route.totalDistance * 1.8),
                               isActive: false)
                }
            }
        }
    }

    private func hazardSimulationSection(building: BuildingPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HAZARD SIMULATION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal, 2)

            ForEach(building.hazardTemplates) { hazard in
                Toggle(isOn: Binding(
                    get: { viewModel.activeHazards.contains { $0.id == hazard.id } },
                    set: { viewModel.toggleHazard(hazard.id, enabled: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hazard.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPri)
                        Text(hazard.severity.rawValue.capitalized + " · " + hazard.status.rawValue.capitalized)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .tint(AppTheme.green)
                .padding(14)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private func instructionIcon(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("stair") { return "arrow.up.right" }
        if t.contains("exit") { return "door.left.hand.open" }
        if t.contains("refuge") { return "figure.roll" }
        if t.contains("continue") { return "arrow.right" }
        if t.contains("start") { return "figure.stand" }
        return "arrow.up.right"
    }

    private func stepIcon(for index: Int) -> String {
        let icons = ["arrow.right", "arrow.up.right", "door.left.hand.open",
                     "figure.walk", "checkmark", "mappin"]
        return icons[min(index, icons.count - 1)]
    }

    private func estimatedTime(for stepIndex: Int) -> String {
        "\(stepIndex + 1) min"
    }

    private func estimatedTotalTime(distance: Double) -> String {
        let seconds = Int(distance / 1.2)
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func timeAgoString() -> String {
        guard let route = viewModel.routeResult else { return "N/A" }
        let seconds = Int(route.totalDistance / 1.2)
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct AltPathCard: View {
    let label: String
    let safePercent: Int
    let time: String
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(isActive ? AppTheme.bg : AppTheme.textPri)
                if isActive {
                    Text("\(safePercent)% Safe")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.bg)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? AppTheme.green : AppTheme.cardBg3)
            .clipShape(Capsule())

            // Safety bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.cardBg3)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? AppTheme.green : AppTheme.textDim)
                        .frame(width: geo.size.width * CGFloat(safePercent) / 100, height: 4)
                }
            }
            .frame(height: 4)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(time)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(AppTheme.textSec)
        }
        .padding(14)
        .frame(width: 130)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(isActive ? AppTheme.green.opacity(0.3) : AppTheme.border, lineWidth: 1))
    }
}

#Preview {
    RouteDetailView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
