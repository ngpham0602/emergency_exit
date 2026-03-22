import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var floorPlanVM = FloorPlanLibraryViewModel()
    @State private var selectedTab = 0
    @State private var showEmergency = false
    @State private var showSendEmergency = false
    @State private var confirmStopAlert = false
    @State private var confirmStopHazard = false

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
                    userContent
                }
            }
            .environmentObject(floorPlanVM)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom tab bar
            VStack(spacing: 0) {
                // Security banner — active alert with STOP button
                if isSecurity, let alert = viewModel.activeEmergencyAlert {
                    HStack(spacing: 10) {
                        Image(systemName: alert.type.icon)
                            .font(.system(size: 13))
                        Text("\(alert.type.notificationTitle) ACTIVE")
                            .font(.system(size: 12, weight: .black))
                            .tracking(0.5)
                        Spacer()
                        Button { confirmStopAlert = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 10))
                                Text("STOP ALERT")
                                    .font(.system(size: 11, weight: .black))
                            }
                            .foregroundStyle(AppTheme.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(AppTheme.red)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Hazard banner — visible to BOTH security and user
                if viewModel.hasReportedHazards && viewModel.activeEmergencyAlert == nil {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                        Text("HAZARD REPORTED")
                            .font(.system(size: 12, weight: .black))
                            .tracking(0.5)
                        Spacer()
                        if isSecurity {
                            Button { confirmStopHazard = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 10))
                                    Text("CLEAR")
                                        .font(.system(size: 11, weight: .black))
                                }
                                .foregroundStyle(AppTheme.amber)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(AppTheme.amber)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // User banner — alert received
                if !isSecurity, let alert = viewModel.activeEmergencyAlert {
                    Button { viewModel.showEmergencyAlert = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: alert.type.icon)
                                .font(.system(size: 13))
                            Text("\(alert.type.notificationTitle) — TAP FOR DETAILS")
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
        .animation(.easeInOut(duration: 0.25), value: viewModel.activeEmergencyAlert?.id)
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasReportedHazards)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showEmergency) {
            EmergencyActiveView().environmentObject(viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showEmergencyAlert) {
            if let alert = viewModel.activeEmergencyAlert {
                UserEmergencyAlertView(alert: alert) {
                    viewModel.navigateToMap()
                }
            }
        }
        .onAppear { viewModel.recomputeRoute() }
        .onChange(of: authVM.userRole) { _ in selectedTab = 0 }
        .confirmationDialog("Stop Emergency Alert", isPresented: $confirmStopAlert, titleVisibility: .visible) {
            Button("Stop Alert", role: .destructive) {
                viewModel.stopEmergencyAlert()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop the emergency alert for all users and clear all notifications.")
        }
        .confirmationDialog("Clear All Hazards", isPresented: $confirmStopHazard, titleVisibility: .visible) {
            Button("Clear Hazards", role: .destructive) {
                viewModel.stopAllHazards()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all reported hazards and recalculate safe routes.")
        }
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
    private var userContent: some View {
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
