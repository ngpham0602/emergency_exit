import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var userName: String
    @Published var userEmail: String
    @Published var userRole: String
    @Published var signInError: String?

    init() {
        isSignedIn = UserDefaults.standard.bool(forKey: "se_signed_in")
        userName   = UserDefaults.standard.string(forKey: "se_name")  ?? "User"
        userEmail  = UserDefaults.standard.string(forKey: "se_email") ?? ""
        userRole   = UserDefaults.standard.string(forKey: "se_role")  ?? "Building Occupant"
    }

    func signIn(email: String, password: String) {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            signInError = "Please enter your email and access key."
            return
        }
        let name = email
            .components(separatedBy: "@").first?
            .replacingOccurrences(of: ".", with: " ")
            .capitalized ?? "User"
        userName   = name
        userEmail  = email
        userRole   = "Level 4 Safety Coordinator"
        isSignedIn = true
        signInError = nil
        UserDefaults.standard.set(true,      forKey: "se_signed_in")
        UserDefaults.standard.set(name,      forKey: "se_name")
        UserDefaults.standard.set(email,     forKey: "se_email")
        UserDefaults.standard.set(userRole,  forKey: "se_role")
    }

    func signOut() {
        isSignedIn = false
        UserDefaults.standard.set(false, forKey: "se_signed_in")
    }
}
