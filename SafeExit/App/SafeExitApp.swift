import SwiftUI
import FireBase


@main
struct SafeExitApp: App {
    @StateObject private var appViewModel  = AppViewModel(container: AppContainer.makeDefault())
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isSignedIn {
                MainTabView()
                    .environmentObject(appViewModel)
                    .environmentObject(authViewModel)
            } else {
                LandingView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
