import XCTest
import OSLog
@testable import BrainIncubator
import Firebase
import FirebaseAnalytics

class MockAnalytics: NSObject {
    static var loggedEvents: [(name: String, parameters: [String: Any]?)] = []
    
    static func logEvent(_ name: String, parameters: [String: Any]?) {
        loggedEvents.append((name: name, parameters: parameters))
    }
    
    static func reset() {
        loggedEvents.removeAll()
    }
}

final class AnalyticsManagerTests: XCTestCase {
    var analyticsManager: AnalyticsManager!
    let analytics = AnalyticsManager.shared
    
    override func setUp() {
        super.setUp()
        analyticsManager = AnalyticsManager.shared
        MockAnalytics.reset()
    }
    
    func testTrackScreenView() throws {
        // Given
        let screenName = "Home"
        
        // When/Then - Verify no crash
        analyticsManager.trackScreenView(screenName: screenName)
    }
    
    func testTrackTrainingProgress() throws {
        // Given
        let moduleId = "test-module"
        let progress = 0.75
        
        // When/Then - Verify no crash
        analyticsManager.trackTrainingProgress(moduleId: moduleId, progress: progress)
    }
    
    func testTrackAssessmentCompletion() throws {
        // Given
        let assessmentId = "test-assessment"
        let score = 85
        
        // When/Then - Verify no crash
        analyticsManager.trackAssessmentCompletion(assessmentId: assessmentId, score: score)
    }
    
    func testTrackError() throws {
        // Given
        struct TestError: Error {
            let message: String
        }
        let error = TestError(message: "Test error")
        let context = "test context"
        
        // When/Then - Verify no crash
        analyticsManager.trackError(error, context: context)
    }
    
    func testTrackUserAction() throws {
        // Given
        let action = "button_tap"
        let parameters = ["screen": "Home", "button": "Start Training"]
        
        // When/Then - Verify no crash
        analyticsManager.trackUserAction(action: action, parameters: parameters)
    }
    
    func testTrackUserActionWithoutParameters() throws {
        // Given
        let action = "view_documentation"
        
        // When/Then - Verify no crash
        analyticsManager.trackUserAction(action: action)
    }
    
    func testUserEngagementTracking() throws {
        analytics.trackUserEngagement("module_view", duration: 300)
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, "user_engagement")
        XCTAssertEqual(event.parameters?["type"] as? String, "module_view")
        XCTAssertEqual(event.parameters?["duration"] as? TimeInterval, 300)
        XCTAssertNotNil(event.parameters?["session_id"])
    }
    
    func testLearningProgressTracking() throws {
        analytics.trackLearningProgress(moduleId: "icd11-basics", progress: 0.75, timeSpent: 1800)
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, "learning_progress")
        XCTAssertEqual(event.parameters?["module_id"] as? String, "icd11-basics")
        XCTAssertEqual(event.parameters?["progress"] as? Double, 0.75)
        XCTAssertEqual(event.parameters?["time_spent"] as? TimeInterval, 1800)
        XCTAssertEqual(event.parameters?["completion_rate"] as? Double, 75.0)
    }
    
    func testSubscriptionEventTracking() throws {
        analytics.trackSubscriptionEvent(type: "purchase", tier: "premium")
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, AnalyticsEventPurchase)
        XCTAssertEqual(event.parameters?[AnalyticsParameterItemID] as? String, "premium")
        XCTAssertEqual(event.parameters?[AnalyticsParameterItemName] as? String, "purchase")
    }
    
    func testErrorTracking() throws {
        analytics.trackError(code: "E404", message: "Resource not found", severity: "warning")
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, "app_error")
        XCTAssertEqual(event.parameters?["error_code"] as? String, "E404")
        XCTAssertEqual(event.parameters?["error_message"] as? String, "Resource not found")
        XCTAssertEqual(event.parameters?["severity"] as? String, "warning")
        XCTAssertNotNil(event.parameters?["timestamp"])
    }
    
    func testScreenViewTracking() throws {
        analytics.trackScreenView(screenName: "Home", screenClass: "HomeView")
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, AnalyticsEventScreenView)
        XCTAssertEqual(event.parameters?[AnalyticsParameterScreenName] as? String, "Home")
        XCTAssertEqual(event.parameters?[AnalyticsParameterScreenClass] as? String, "HomeView")
    }
    
    func testAppVersionTracking() throws {
        analytics.trackAppVersion(version: "1.0.0", buildNumber: "42")
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, "app_version")
        XCTAssertEqual(event.parameters?["version"] as? String, "1.0.0")
        XCTAssertEqual(event.parameters?["build_number"] as? String, "42")
        XCTAssertEqual(event.parameters?["deployment_type"] as? String, "app_store")
    }
    
    func testOnboardingCompletionTracking() throws {
        let steps = ["welcome", "profile", "preferences"]
        analytics.trackOnboardingCompletion(steps: steps, duration: 300)
        
        let event = try XCTUnwrap(MockAnalytics.loggedEvents.first)
        XCTAssertEqual(event.name, "onboarding_completion")
        XCTAssertEqual(event.parameters?["steps_completed"] as? [String], steps)
        XCTAssertEqual(event.parameters?["duration"] as? TimeInterval, 300)
        XCTAssertEqual(event.parameters?["success_rate"] as? Double, 60.0)
    }
    
    func testBatchEventTracking() throws {
        // Simulate user session
        analytics.trackScreenView(screenName: "Home", screenClass: "HomeView")
        analytics.trackUserAction(action: "start_training", context: "home")
        analytics.trackLearningProgress(moduleId: "icd11-basics", progress: 0.5, timeSpent: 900)
        analytics.trackFeatureUsage(featureId: "quick_search")
        
        XCTAssertEqual(MockAnalytics.loggedEvents.count, 4)
        XCTAssertEqual(MockAnalytics.loggedEvents[0].name, AnalyticsEventScreenView)
        XCTAssertEqual(MockAnalytics.loggedEvents[1].name, "user_action")
        XCTAssertEqual(MockAnalytics.loggedEvents[2].name, "learning_progress")
        XCTAssertEqual(MockAnalytics.loggedEvents[3].name, "feature_usage")
    }
}