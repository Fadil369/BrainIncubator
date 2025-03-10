import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

enum AuthError: Error {
    case signInFailed
    case signUpFailed
    case signOutFailed
    case userNotFound
    case invalidEmail
    case weakPassword
    case emailInUse
}

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
            }
            AnalyticsManager.shared.trackUserAction(
                action: "user_sign_in",
                parameters: ["method": "email"]
            )
        } catch {
            AnalyticsManager.shared.trackError(error, context: "AuthenticationManager.signIn")
            throw AuthError.signInFailed
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile
            let db = Firestore.firestore()
            try await db.collection("users").document(result.user.uid).setData([
                "email": email,
                "name": name,
                "createdAt": Date(),
                "subscription": "none"
            ])
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
            }
            
            AnalyticsManager.shared.trackUserAction(
                action: "user_sign_up",
                parameters: ["method": "email"]
            )
        } catch {
            AnalyticsManager.shared.trackError(error, context: "AuthenticationManager.signUp")
            throw AuthError.signUpFailed
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
            }
            AnalyticsManager.shared.trackUserAction(action: "user_sign_out")
        } catch {
            AnalyticsManager.shared.trackError(error, context: "AuthenticationManager.signOut")
            throw AuthError.signOutFailed
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            AnalyticsManager.shared.trackUserAction(
                action: "password_reset_requested",
                parameters: ["email": email]
            )
        } catch {
            AnalyticsManager.shared.trackError(error, context: "AuthenticationManager.resetPassword")
            throw error
        }
    }
}