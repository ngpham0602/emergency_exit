import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Accessibility
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.roll")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.green)
                            Text("ACCESSIBILITY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(AppTheme.textSec)
                        }

                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.cardBg3)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "figure.roll")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Wheelchair-safe routing")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                                Text("Avoid stairs, use accessible paths only.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            Spacer()
                            Toggle("", isOn: $viewModel.accessibilityMode)
                                .tint(AppTheme.green)
                                .labelsHidden()
                        }

                        Divider().background(AppTheme.divider)

                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.cardBg3)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audio Guidance")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                                Text("Spoken turn-by-turn evacuation instructions.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            Spacer()
                            Toggle("", isOn: $viewModel.prefersAudioGuidance)
                                .tint(AppTheme.green)
                                .labelsHidden()
                        }
                    }
                    .padding(16)
                    .background(AppTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))

                    // Building info
                    if let building = viewModel.buildingPackage {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSec)
                                Text("BUILDING INFO")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.textSec)
                            }

                            HStack {
                                Text("Package")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSec)
                                Spacer()
                                Text("\(building.metadata.name) v\(building.metadata.version)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                            }

                            HStack {
                                Text("Nodes")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSec)
                                Spacer()
                                Text("\(building.nodes.count)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                            }

                            HStack {
                                Text("Exits")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSec)
                                Spacer()
                                Text("\(building.exits.count)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPri)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
