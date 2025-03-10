import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Theme.primaryOrange)
            
            Text("Welcome Back")
                .font(.title)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 16) {
                TextField("Email".localized, text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password".localized, text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
            }
            
            Button(action: { showForgotPassword = true }) {
                Text("Forgot Password?".localized)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Button(action: signIn) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In".localized)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
            
            HStack {
                Text("Don't have an account?".localized)
                    .foregroundColor(Theme.textSecondary)
                
                NavigationLink("Sign Up".localized) {
                    SignUpView()
                }
                .foregroundColor(Theme.primaryOrange)
            }
        }
        .padding()
        .background(Theme.darkBackground)
        .alert("Error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await viewModel.signIn(email: email, password: password)
            } catch {
                showError = true
            }
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Theme.surfaceDark)
            .cornerRadius(10)
            .foregroundColor(Theme.textPrimary)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.primaryOrange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}