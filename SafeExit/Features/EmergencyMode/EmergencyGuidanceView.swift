import SwiftUI

struct EmergencyGuidanceView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppTheme.emergencyBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                if let route = viewModel.routeResult {
                    Text(route.destinationKind == .exit ? "EVACUATE" : "GO TO REFUGE")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Image(systemName: route.destinationKind == .exit
                          ? "arrow.up.right.circle.fill" : "figure.roll")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundStyle(.white)

                    Text(route.instructions.first?.detail ?? "Follow the next instruction.")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(route.instructions.prefix(3)) { instruction in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instruction.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(instruction.detail)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Distance badge
                    HStack {
                        Spacer()
                        Text("\(Int(route.totalDistance))m to safety")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                        Spacer()
                    }

                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("No route loaded.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Select a starting room to compute a route.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EmergencyGuidanceView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
