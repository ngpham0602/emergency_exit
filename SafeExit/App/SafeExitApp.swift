import SwiftUI
import Firebase


@main
struct SafeExitApp: App {
    // Wire up AppDelegate for APNs + FCM push notification support
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appViewModel  = AppViewModel(container: AppContainer.makeDefault())
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()

        // Request local notification permission (critical alerts)
        EmergencyNotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isSignedIn {
                MainTabView()
                    .environmentObject(appViewModel)
                    .environmentObject(authViewModel)
                    .onAppear { setupNotificationDeepLink() }
            } else {
                LandingView()
                    .environmentObject(authViewModel)
            }
        }
    }

    /// When user taps an emergency notification (local or push), navigate to map.
    private func setupNotificationDeepLink() {
        let vm = appViewModel
        EmergencyNotificationManager.shared.onNotificationTapped = { _ in
            Task { @MainActor in
                if vm.activeEmergencyAlert != nil {
                    vm.showEmergencyAlert = true
                } else {
                    vm.navigateToMap()
                }
            }
        }
    }
}
