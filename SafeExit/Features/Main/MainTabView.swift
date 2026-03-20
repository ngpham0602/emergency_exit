import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedTab = 0
    @State private var showEmergency = false

    private var hasBlockedHazard: Bool {
        viewModel.activeHazards.contains { $0.severity == .blocked }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bg.ignoresSafeArea()

            // Tab content — fills above the custom tab bar
            Group {
                switch selectedTab {
                case 0: LiveMapView()
                case 1: RouteDetailView()
                case 2: ProfileView()
                default: LiveMapView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80) // make room for tab bar

            // Custom tab bar
            VStack(spacing: 0) {
                // Emergency banner strip (appears above tab bar when hazard active)
                if hasBlockedHazard {
                    Button { showEmergency = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                            Text("EMERGENCY ACTIVE — TAP TO VIEW")
                                .font(.system(size: 12, weight: .black))
                                .tracking(0.5)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(AppTheme.red)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Tab bar
                HStack(spacing: 0) {
                    TabBarItem(icon: "map.fill",                   label: "Map",    index: 0, selected: $selectedTab)
                    TabBarItem(icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Route",  index: 1, selected: $selectedTab)
                    TabBarItem(icon: "person.fill",                label: "Profile", index: 2, selected: $selectedTab)
                }
                .frame(height: 60)
                .background(AppTheme.cardBg)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppTheme.divider).frame(height: 1)
                }
                // bottom safe area fill
                .background(
                    AppTheme.cardBg.ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: hasBlockedHazard)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showEmergency) {
            EmergencyActiveView()
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.recomputeRoute()
        }
    }
}

// MARK: - Tab bar item

private struct TabBarItem: View {
    let icon: String
    let label: String
    let index: Int
    @Binding var selected: Int

    var isSelected: Bool { selected == index }

    var body: some View {
        Button { selected = index } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.green : AppTheme.textDim)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.green : AppTheme.textDim)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .environmentObject(AuthViewModel())
}
