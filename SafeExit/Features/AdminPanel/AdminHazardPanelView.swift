import SwiftUI

struct AdminHazardPanelView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.bg)
                    }
                    Text("Hazard Panel")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPri)
                    Spacer()

                    if !viewModel.activeHazards.isEmpty {
                        Text("\(viewModel.activeHazards.count) ACTIVE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.redDim)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Active route state
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.green)
                                Text("ROUTE STATE")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.textSec)
                            }

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.routeResult?.destinationKind == .refugePoint
                                              ? AppTheme.amber.opacity(0.15)
                                              : AppTheme.greenDim)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: viewModel.routeResult?.destinationKind == .refugePoint
                                          ? "figure.roll" : "door.left.hand.open")
                                        .font(.system(size: 18))
                                        .foregroundStyle(viewModel.routeResult?.destinationKind == .refugePoint
                                                         ? AppTheme.amber : AppTheme.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.routeResult?.destinationKind == .refugePoint
                                         ? "Fallback to refuge point"
                                         : "Exit route available")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.textPri)
                                    Text("Hazards active: \(viewModel.activeHazards.count)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.textSec)
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))

                        // Simulation controls
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.amber)
                                Text("SIMULATION CONTROLS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.textSec)
                            }

                            Button {
                                viewModel.resetHazards()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 14))
                                    Text("Reset All Hazards")
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
                        }
                        .padding(16)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))

                        // Demo hazard toggles
                        if let building = viewModel.buildingPackage {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppTheme.red)
                                    Text("DEMO HAZARDS")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .tracking(2)
                                        .foregroundStyle(AppTheme.textSec)
                                }

                                ForEach(building.hazardTemplates) { hazard in
                                    let isActive = viewModel.activeHazards.contains { $0.id == hazard.id }

                                    Toggle(isOn: Binding(
                                        get: { isActive },
                                        set: { viewModel.toggleHazard(hazard.id, enabled: $0) }
                                    )) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(isActive ? AppTheme.redDim : AppTheme.cardBg3)
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(isActive ? AppTheme.red : AppTheme.textDim)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(hazard.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AppTheme.textPri)
                                                Text("\(hazard.severity.rawValue.capitalized) · \(hazard.status.rawValue.capitalized)")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(AppTheme.textSec)
                                            }
                                        }
                                    }
                                    .tint(AppTheme.red)
                                    .padding(12)
                                    .background(AppTheme.cardBg2)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

#Preview {
    AdminHazardPanelView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
