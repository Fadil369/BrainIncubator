import SwiftUI
import PassKit

struct SubscriptionView: View {
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Choose Your Plan".localized)
                        .font(.title)
                        .foregroundColor(Theme.textPrimary)
                    
                    // Basic Plan
                    SubscriptionCard(
                        tier: .basic,
                        title: "Basic Plan".localized,
                        price: "$9.99",
                        features: [
                            "Access to basic training modules",
                            "Limited assessments",
                            "Basic documentation"
                        ],
                        isSelected: selectedTier == .basic
                    ) {
                        selectedTier = .basic
                    }
                    
                    // Pro Plan
                    SubscriptionCard(
                        tier: .pro,
                        title: "Pro Plan".localized,
                        price: "$19.99",
                        features: [
                            "All basic features",
                            "Advanced training modules",
                            "Unlimited assessments",
                            "Complete documentation",
                            "Priority support"
                        ],
                        isSelected: selectedTier == .pro
                    ) {
                        selectedTier = .pro
                    }
                    
                    // Enterprise Plan
                    SubscriptionCard(
                        tier: .enterprise,
                        title: "Enterprise Plan".localized,
                        price: "$99.99",
                        features: [
                            "All pro features",
                            "Custom training modules",
                            "Team analytics",
                            "API access",
                            "Dedicated support",
                            "Custom integrations"
                        ],
                        isSelected: selectedTier == .enterprise
                    ) {
                        selectedTier = .enterprise
                    }
                    
                    VStack(spacing: 16) {
                        if paymentManager.canMakePayments() {
                            ApplePayButton(
                                action: subscribe,
                                type: .buy,
                                style: .black
                            )
                            .frame(minWidth: 100, maxWidth: .infinity)
                            .frame(height: 45)
                            .disabled(selectedTier == nil || isProcessing)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationBarItems(
                trailing: Button("Skip".localized) {
                    dismiss()
                }
                .foregroundColor(Theme.textSecondary)
            )
            .alert("Error".localized, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func subscribe() {
        guard let tier = selectedTier else { return }
        
        isProcessing = true
        Task {
            do {
                try await paymentManager.subscribe(to: tier)
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

struct ApplePayButton: View {
    let action: () -> Void
    let type: PKPaymentButtonType
    let style: PKPaymentButtonStyle
    
    var body: some View {
        PaymentButton(type: type, style: style) {
            action()
        }
    }
}

struct PaymentButton: UIViewRepresentable {
    let type: PKPaymentButtonType
    let style: PKPaymentButtonStyle
    let action: () -> Void
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

struct SubscriptionCard: View {
    let tier: SubscriptionTier
    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(price + "/month".localized)
                            .font(.subheadline)
                            .foregroundColor(Theme.primaryOrange)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? Theme.primaryOrange : Theme.textSecondary)
                }
                
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(Theme.primaryOrange)
                        
                        Text(feature.localized)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.surfaceDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.primaryOrange : Color.clear, lineWidth: 2)
            )
        }
    }
}