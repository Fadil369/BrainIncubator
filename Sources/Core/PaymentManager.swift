import SwiftUI
import PassKit
import FirebaseFirestore

enum PaymentError: Error {
    case setupFailed
    case paymentFailed
    case subscriptionFailed
    case invalidAmount
    case userNotAuthenticated
    case applePayNotAvailable
}

enum SubscriptionTier: String {
    case basic = "basic_monthly"
    case pro = "pro_monthly"
    case enterprise = "enterprise_yearly"
}

class PaymentManager: NSObject, ObservableObject {
    static let shared = PaymentManager()
    
    @Published var isLoading = false
    @Published var currentSubscription: SubscriptionTier?
    
    // Apple Pay configuration
    private let merchantIdentifier = "merchant.com.brainincubator" // Replace with your merchant ID
    private var paymentController: PKPaymentAuthorizationController?
    
    private override init() {
        super.init()
        loadCurrentSubscription()
    }
    
    private func loadCurrentSubscription() {
        guard let userId = AuthenticationManager.shared.user?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let subscriptionString = data["subscription"] as? String else { return }
            
            DispatchQueue.main.async {
                self?.currentSubscription = SubscriptionTier(rawValue: subscriptionString)
            }
        }
    }
    
    // Check if Apple Pay is available on the device
    func canMakePayments() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }
    
    // Create payment request for Apple Pay
    private func createPaymentRequest(amount: Int, description: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Convert cents to dollars for display
        let decimalAmount = NSDecimalNumber(value: amount).dividing(by: NSDecimalNumber(value: 100))
        
        let item = PKPaymentSummaryItem(label: description,
                                      amount: decimalAmount,
                                      type: .final)
        request.paymentSummaryItems = [item]
        
        return request
    }
    
    // Handle Apple Pay payment
    func makePaymentWithApplePay(amount: Int, description: String) async throws -> Bool {
        guard canMakePayments() else {
            throw PaymentError.applePayNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = createPaymentRequest(amount: amount, description: description)
            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self
            
            self.paymentController = controller
            
            controller.present { presented in
                if !presented {
                    continuation.resume(throwing: PaymentError.setupFailed)
                    return
                }
            }
            
            // Store continuation to complete it when payment is done
            self.paymentContinuation = continuation
        }
    }
    
    private var paymentContinuation: CheckedContinuation<Bool, Error>?
    
    func subscribe(to tier: SubscriptionTier) async throws {
        guard AuthenticationManager.shared.isAuthenticated,
              let userId = AuthenticationManager.shared.user?.uid else {
            throw PaymentError.userNotAuthenticated
        }
        
        do {
            let amount = getSubscriptionAmount(for: tier)
            let description = "Subscribe to \(tier.rawValue.capitalized)"
            
            // Try Apple Pay first
            if canMakePayments() {
                let success = try await makePaymentWithApplePay(amount: amount, description: description)
                if success {
                    // Update subscription in Firestore
                    let db = Firestore.firestore()
                    try await db.collection("users").document(userId).updateData([
                        "subscription": tier.rawValue,
                        "subscriptionUpdatedAt": Date()
                    ])
                    
                    DispatchQueue.main.async {
                        self.currentSubscription = tier
                    }
                    
                    AnalyticsManager.shared.trackUserAction(
                        action: "subscription_updated_apple_pay",
                        parameters: ["tier": tier.rawValue]
                    )
                    return
                }
            }
            
            throw PaymentError.paymentFailed
            
        } catch {
            AnalyticsManager.shared.trackError(error, context: "PaymentManager.subscribe")
            throw PaymentError.subscriptionFailed
        }
    }
    
    private func getSubscriptionAmount(for tier: SubscriptionTier) -> Int {
        switch tier {
        case .basic:
            return 999 // $9.99
        case .pro:
            return 1999 // $19.99
        case .enterprise:
            return 9999 // $99.99
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension PaymentManager: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                      didAuthorizePayment payment: PKPayment,
                                      handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Here you would typically send the payment token to your server
        // and handle the payment processing there
        
        // For this example, we'll simulate a successful payment
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        paymentContinuation?.resume(returning: true)
        paymentContinuation = nil
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            if self.paymentContinuation != nil {
                self.paymentContinuation?.resume(returning: false)
                self.paymentContinuation = nil
            }
        }
    }
}