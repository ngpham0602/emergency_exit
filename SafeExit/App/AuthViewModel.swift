import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - User role

enum UserRole: String, Codable {
    case security = "security"
    case employee = "employee"

    var displayName: String {
        switch self {
        case .security: return "Security Officer"
        case .employee: return "User"
        }
    }

    var icon: String {
        switch self {
        case .security: return "shield.checkered"
        case .employee: return "person.fill"
        }
    }
}

// MARK: - Auth view model

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userName:   String = ""
    @Published var userEmail:  String = ""
    @Published var userRole:   UserRole = .employee
    @Published var isLoading:  Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    init() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? ""
            userName  = user.displayName ?? ""
            isSignedIn = true
            Task { await fetchRole(uid: user.uid) }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                userEmail = email
                await fetchRole(uid: result.user.uid)
                isSignedIn = true
            } catch {
                errorMessage = friendlyError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Register

    func register(name: String, email: String, password: String, role: UserRole) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your full name."
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let uid = result.user.uid

                // Set display name
                let req = result.user.createProfileChangeRequest()
                req.displayName = name
                try await req.commitChanges()

                // Persist role in Firestore
                try await db.collection("users").document(uid).setData([
                    "name":      name,
                    "email":     email,
                    "role":      role.rawValue,
                    "createdAt": FieldValue.serverTimestamp()
                ])

                userName  = name
                userEmail = email
                userRole  = role
                isSignedIn = true
            } catch {
                errorMessage = friendlyError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        isSignedIn  = false
        userName    = ""
        userEmail   = ""
        userRole    = .employee
        errorMessage = nil
    }

    // MARK: - Helpers

    private func fetchRole(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let data = doc.data(),
               let raw  = data["role"] as? String,
               let role = UserRole(rawValue: raw) {
                userRole = role
                userName = data["name"] as? String ?? userName
            }
        } catch {
            userRole = .employee
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .wrongPassword:      return "Incorrect password. Please try again."
        case .userNotFound:       return "No account found with this email."
        case .emailAlreadyInUse:  return "This email is already registered. Try signing in."
        case .weakPassword:       return "Password too weak — use at least 6 characters."
        case .invalidEmail:       return "Invalid email address."
        case .networkError:       return "Network error. Check your connection."
        default:                  return error.localizedDescription
        }
    }
}
