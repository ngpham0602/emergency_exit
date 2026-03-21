import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var floorPlanVM = FloorPlanLibraryViewModel()
    @State private var selectedTab = 0
    @State private var showEmergency = false

    private var isSecurity: Bool { authVM.userRole == .security }

    private var hasBlockedHazard: Bool {
        viewModel.activeHazards.contains { $0.severity == .blocked }
    }

    // MARK: - Tab definitions

    private struct TabDef {
        let icon: String
        let label: String
    }

    private var tabs: [TabDef] {
        if isSecurity {
            return [
                TabDef(icon: "map.fill",                                   label: "Map"),
                TabDef(icon: "building.2.fill",                            label: "Plans"),
                TabDef(icon: "exclamationmark.triangle.fill",              label: "Admin"),
                TabDef(icon: "arrow.triangle.turn.up.right.diamond.fill",  label: "Route"),
                TabDef(icon: "person.fill",                                label: "Profile"),
            ]
        } else {
            return [
                TabDef(icon: "map.fill",                                   label: "Map"),
                TabDef(icon: "arrow.triangle.turn.up.right.diamond.fill",  label: "Route"),
                TabDef(icon: "person.fill",                                label: "Profile"),
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bg.ignoresSafeArea()

            // Tab content
            Group {
                if isSecurity {
                    securityContent
                } else {
                    employeeContent
                }
            }
            .environmentObject(floorPlanVM)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom tab bar
            VStack(spacing: 0) {
                // Emergency banner (security only)
                if isSecurity && hasBlockedHazard {
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
                    ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                        TabBarItem(icon: tab.icon, label: tab.label,
                                   index: i, selected: $selectedTab,
                                   accentColor: isSecurity ? AppTheme.amber : AppTheme.green)
                    }
                }
                .frame(height: 60)
                .background(AppTheme.cardBg)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppTheme.divider).frame(height: 1)
                }
                .background(AppTheme.cardBg.ignoresSafeArea(edges: .bottom))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: hasBlockedHazard)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showEmergency) {
            EmergencyActiveView().environmentObject(viewModel)
        }
        .onAppear { viewModel.recomputeRoute() }
        .onChange(of: authVM.userRole) { _ in selectedTab = 0 }
    }

    // MARK: - Role-specific content

    @ViewBuilder
    private var securityContent: some View {
        switch selectedTab {
        case 0: MapEditorView()
        case 1: FloorPlanLibraryView()
        case 2: AdminHazardPanelView()
        case 3: RouteDetailView()
        case 4: ProfileView()
        default: MapEditorView()
        }
    }

    @ViewBuilder
    private var employeeContent: some View {
        switch selectedTab {
        case 0: MapEditorView()
        case 1: RouteDetailView()
        case 2: ProfileView()
        default: MapEditorView()
        }
    }
}

// MARK: - Tab bar item

private struct TabBarItem: View {
    let icon: String
    let label: String
    let index: Int
    @Binding var selected: Int
    let accentColor: Color

    var isSelected: Bool { selected == index }

    var body: some View {
        Button { selected = index } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? accentColor : AppTheme.textDim)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? accentColor : AppTheme.textDim)
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
