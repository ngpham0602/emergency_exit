import SwiftUI
import FireBase

@main
struct SafeExitApp: App {
    @StateObject private var appViewModel  = AppViewModel(container: AppContainer.makeDefault())
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            FirebaseTestView() 
        }
    }
}
