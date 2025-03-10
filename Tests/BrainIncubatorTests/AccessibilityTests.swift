import XCTest
@testable import BrainIncubator

final class AccessibilityTests: XCTestCase {
    func testHomeViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test progress elements
        XCTAssertTrue(app.staticTexts["Progress Overview"].exists)
        XCTAssertTrue(app.progressIndicators["Overall progress"].exists)
        
        // Test quick actions
        XCTAssertTrue(app.buttons["Continue Training"].exists)
        XCTAssertTrue(app.buttons["Assessment"].exists)
        XCTAssertTrue(app.buttons["Documentation"].exists)
        XCTAssertTrue(app.buttons["Help & Support"].exists)
    }
    
    func testTrainingViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Training"].tap()
        
        // Test search functionality
        XCTAssertTrue(app.searchFields["Search training modules"].exists)
        
        // Test module cards
        for module in ["ICD-11 Basics", "Transition Guidelines", "Code Mapping"] {
            XCTAssertTrue(app.buttons[module].exists)
        }
    }
    
    func testAssessmentViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Assessment"].tap()
        
        // Test category selector
        XCTAssertTrue(app.pickers["Assessment category selector"].exists)
        
        // Test progress indicator
        XCTAssertTrue(app.staticTexts["Assessment progress"].exists)
        
        // Test assessment items
        XCTAssertTrue(app.buttons["ICD-11 Knowledge"].exists)
        XCTAssertTrue(app.buttons["Team Competency"].exists)
    }
    
    func testDocumentationViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Docs"].tap()
        
        // Test section selector
        XCTAssertTrue(app.pickers["Documentation section selector"].exists)
        
        // Test document cards
        XCTAssertTrue(app.buttons["Implementation Guide guideline"].exists)
        XCTAssertTrue(app.buttons["ICD-11 Reference Manual reference document"].exists)
    }
    
    func testSettingsViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        
        // Test toggles
        XCTAssertTrue(app.switches["Enable Notifications"].exists)
        XCTAssertTrue(app.switches["Dark Mode"].exists)
        
        // Test navigation links
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Help & Support"].exists)
    }
}