import XCTest
import UserNotifications
@testable import BrainIncubator

final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    var notificationCenter: UNUserNotificationCenter!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager.shared
        notificationCenter = UNUserNotificationCenter.current()
    }
    
    override func tearDown() {
        notificationCenter.removeAllPendingNotificationRequests()
        super.tearDown()
    }
    
    func testScheduleTrainingReminder() throws {
        // Given
        let moduleTitle = "ICD-11 Basics"
        
        // When
        notificationManager.scheduleTrainingReminder(moduleTitle: moduleTitle)
        
        // Then
        let expectation = XCTestExpectation(description: "Fetch pending notifications")
        
        notificationCenter.getPendingNotificationRequests { requests in
            XCTAssertTrue(requests.contains { request in
                request.content.title == "Continue Your ICD-11 Training" &&
                request.content.body.contains(moduleTitle)
            })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testScheduleAssessmentReminder() throws {
        // Given
        let assessmentTitle = "Self Assessment"
        
        // When
        notificationManager.scheduleAssessmentReminder(assessmentTitle: assessmentTitle)
        
        // Then
        let expectation = XCTestExpectation(description: "Fetch pending notifications")
        
        notificationCenter.getPendingNotificationRequests { requests in
            XCTAssertTrue(requests.contains { request in
                request.content.title == "ICD-11 Assessment Due" &&
                request.content.body.contains(assessmentTitle)
            })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testScheduleWeeklyProgressReminder() throws {
        // When
        notificationManager.scheduleWeeklyProgressReminder()
        
        // Then
        let expectation = XCTestExpectation(description: "Fetch pending notifications")
        
        notificationCenter.getPendingNotificationRequests { requests in
            XCTAssertTrue(requests.contains { request in
                request.content.title == "Weekly ICD-11 Progress Check"
            })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancelAllNotifications() throws {
        // Given
        notificationManager.scheduleWeeklyProgressReminder()
        notificationManager.scheduleTrainingReminder(moduleTitle: "Test Module")
        
        // When
        notificationManager.cancelAllNotifications()
        
        // Then
        let expectation = XCTestExpectation(description: "Fetch pending notifications")
        
        notificationCenter.getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}