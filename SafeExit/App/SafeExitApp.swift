import SwiftUI
import Firebase

@main
struct SafeExitApp: App {
    @StateObject private var appViewModel  = AppViewModel(container: AppContainer.makeDefault())
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            FirebaseTestView() 
        }
    }
}
