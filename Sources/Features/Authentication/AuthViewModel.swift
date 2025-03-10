import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            try await AuthenticationManager.shared.signIn(email: email, password: password)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid email or password"
            }
            throw error
        } finally {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            try await AuthenticationManager.shared.signUp(email: email, password: password, name: name)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create account"
            }
            throw error
        } finally {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = ""
        
        do {
            try await AuthenticationManager.shared.resetPassword(email: email)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to send reset email"
            }
            throw error
        } finally {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}