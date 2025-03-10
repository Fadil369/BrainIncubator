import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Reset Password".localized)
                    .font(.title)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Enter your email address and we'll send you instructions to reset your password.".localized)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("Email".localized, text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button(action: resetPassword) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link".localized)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(email.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(Theme.darkBackground)
            .navigationBarItems(
                trailing: Button("Close".localized) {
                    dismiss()
                }
                .foregroundColor(Theme.textSecondary)
            )
            .alert("Error".localized, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Password reset instructions have been sent to your email.".localized)
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await viewModel.resetPassword(email: email)
                showSuccess = true
            } catch {
                showError = true
            }
        }
    }
}