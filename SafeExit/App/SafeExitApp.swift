import SwiftUI

@main
struct SafeExitApp: App {
    @StateObject private var appViewModel = AppViewModel(
        container: AppContainer.makeDefault()
    )

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appViewModel)
        }
    }
}
