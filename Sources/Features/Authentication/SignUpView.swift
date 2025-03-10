import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showError = false
    @State private var showSubscription = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Theme.primaryOrange)
            
            Text("Create Account".localized)
                .font(.title)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 16) {
                TextField("Name".localized, text: $name)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Email".localized, text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password".localized, text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
            }
            
            Button(action: signUp) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign Up".localized)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || name.isEmpty || viewModel.isLoading)
            
            HStack {
                Text("Already have an account?".localized)
                    .foregroundColor(Theme.textSecondary)
                
                NavigationLink("Sign In".localized) {
                    SignInView()
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
        .fullScreenCover(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await viewModel.signUp(email: email, password: password, name: name)
                showSubscription = true
            } catch {
                showError = true
            }
        }
    }
}