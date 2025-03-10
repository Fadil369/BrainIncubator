import Foundation
import OSLog
import Firebase
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    private let logger = Logger(subsystem: "com.brainincubator.app", category: "analytics")
    
    private init() {}
    
    // MARK: - User Analytics
    func trackUserEngagement(_ type: String, duration: TimeInterval) {
        Analytics.logEvent("user_engagement", parameters: [
            "type": type,
            "duration": duration,
            "session_id": UUID().uuidString
        ])
    }
    
    func trackLearningProgress(moduleId: String, progress: Double, timeSpent: TimeInterval) {
        Analytics.logEvent("learning_progress", parameters: [
            "module_id": moduleId,
            "progress": progress,
            "time_spent": timeSpent,
            "completion_rate": progress * 100
        ])
    }
    
    // MARK: - Performance Analytics
    func trackAppStartup(duration: TimeInterval) {
        Analytics.logEvent("app_startup", parameters: [
            "duration": duration,
            "is_cold_start": true
        ])
    }
    
    func trackNetworkCall(endpoint: String, duration: TimeInterval, statusCode: Int) {
        Analytics.logEvent("network_performance", parameters: [
            "endpoint": endpoint,
            "duration": duration,
            "status_code": statusCode
        ])
    }
    
    // MARK: - Business Analytics
    func trackSubscriptionEvent(type: String, tier: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: tier,
            AnalyticsParameterItemName: type,
            "subscription_tier": tier
        ])
    }
    
    func trackFeatureUsage(featureId: String) {
        Analytics.logEvent("feature_usage", parameters: [
            "feature_id": featureId,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Error Tracking
    func trackError(code: String, message: String, severity: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_code": code,
            "error_message": message,
            "severity": severity,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Deployment Analytics
    func trackAppVersion(version: String, buildNumber: String) {
        Analytics.logEvent("app_version", parameters: [
            "version": version,
            "build_number": buildNumber,
            "deployment_type": "app_store"
        ])
    }
    
    func trackOnboardingCompletion(steps: [String], duration: TimeInterval) {
        Analytics.logEvent("onboarding_completion", parameters: [
            "steps_completed": steps,
            "duration": duration,
            "success_rate": (Double(steps.count) / 5.0) * 100 // Assuming 5 total steps
        ])
    }
    
    // MARK: - Usage Analytics
    func trackScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    func trackUserAction(action: String, context: String) {
        Analytics.logEvent("user_action", parameters: [
            "action": action,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Legacy Analytics
    func trackScreenView(screenName: String) {
        logger.info("Screen viewed: \(screenName)")
        #if !DEBUG
        // In a production app, you would send this to your analytics service
        #endif
    }
    
    func trackTrainingProgress(moduleId: String, progress: Double) {
        logger.info("Training progress: \(moduleId) - \(progress)")
        #if !DEBUG
        // Send to analytics service in production
        #endif
    }
    
    func trackAssessmentCompletion(assessmentId: String, score: Int) {
        logger.info("Assessment completed: \(assessmentId) - Score: \(score)")
        #if !DEBUG
        // Send to analytics service in production
        #endif
    }
    
    func trackError(_ error: Error, context: String) {
        logger.error("Error in \(context): \(error.localizedDescription)")
        #if !DEBUG
        // Send to crash reporting service in production
        #endif
    }
    
    func trackUserAction(action: String, parameters: [String: Any]? = nil) {
        var logMessage = "User action: \(action)"
        if let parameters = parameters {
            logMessage += " - Parameters: \(parameters)"
        }
        logger.info("\(logMessage)")
        #if !DEBUG
        // Send to analytics service in production
        #endif
    }
}