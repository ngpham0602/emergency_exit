import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                RouteOverviewView()
            }
            .tabItem {
                Label("Route", systemImage: "figure.walk")
            }

            NavigationStack {
                AdminHazardPanelView()
            }
            .tabItem {
                Label("Admin", systemImage: "exclamationmark.triangle")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(.red)
        .preferredColorScheme(.light)
        .onAppear {
            viewModel.recomputeRoute()
        }
    }
}
