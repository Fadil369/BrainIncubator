import XCTest
import SwiftUI
@testable import BrainIncubator

class ScreenshotGenerator: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["UITEST_SCREENSHOTS"]
    }
    
    func testGenerateAppStoreScreenshots() throws {
        // Prepare test data
        app.launch()
        
        // Home Screen
        snapshot("01_Home")
        
        // Training Module
        app.buttons["Start Training"].tap()
        snapshot("02_Training")
        
        // Assessment View
        app.buttons["Take Assessment"].tap()
        snapshot("03_Assessment")
        
        // Learning Insights
        app.tabBars.buttons["Insights"].tap()
        snapshot("04_Insights")
        
        // Settings & Profile
        app.tabBars.buttons["Profile"].tap()
        snapshot("05_Profile")
    }
    
    func testGenerateDarkModeScreenshots() throws {
        // Set dark mode
        app.launchArguments += ["UI_APPEARANCE_DARK"]
        app.launch()
        
        // Dark mode variants
        snapshot("06_Home_Dark")
        
        app.buttons["Start Training"].tap()
        snapshot("07_Training_Dark")
    }
    
    func testGenerateLocalizedScreenshots() throws {
        // Generate for each supported locale
        let locales = ["en", "es", "fr", "de", "ja"]
        
        for locale in locales {
            app.launchArguments += ["-AppleLanguages", "(\(locale))"]
            app.launch()
            
            snapshot("\(locale)_01_Home")
            
            app.buttons["Start Training"].tap()
            snapshot("\(locale)_02_Training")
        }
    }
    
    func testAccessibilityScreenshots() throws {
        // Demonstrate accessibility features
        app.launchArguments += ["UI_ACCESSIBILITY_ENABLED"]
        app.launch()
        
        snapshot("accessibility_01_VoiceOver")
        
        app.buttons["Increase Text Size"].tap()
        snapshot("accessibility_02_LargeText")
    }
}

// Helper to initialize test data
extension ScreenshotGenerator {
    func setupTestData() {
        let context = CoreDataManager.shared.container.viewContext
        
        // Clear existing data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TrainingProgress")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        // Add sample training progress
        let modules = [
            ("icd11-basics", 0.75),
            ("transition-guidelines", 0.5),
            ("code-mapping", 0.25),
            ("best-practices", 0.0)
        ]
        
        for (moduleId, progress) in modules {
            let progressEntity = TrainingProgress(context: context)
            progressEntity.id = UUID()
            progressEntity.moduleId = moduleId
            progressEntity.progress = progress
            progressEntity.startedAt = Date()
            if progress >= 1.0 {
                progressEntity.completedAt = Date()
            }
        }
        
        // Add sample assessments
        let assessments = [
            ("self-assessment-1", "Self-Assessment", 85),
            ("team-assessment-1", "Team Assessment", 75),
            ("org-assessment-1", "Organization Assessment", 90)
        ]
        
        for (itemId, category, score) in assessments {
            let assessment = AssessmentProgress(context: context)
            assessment.id = UUID()
            assessment.itemId = itemId
            assessment.category = category
            assessment.score = Int16(score)
            assessment.startedAt = Date().addingTimeInterval(-86400) // Yesterday
            assessment.completedAt = Date()
        }
        
        // Add sample activities
        let activities = [
            ("Completed ICD-11 Basics Module", "training"),
            ("Finished Team Assessment", "assessment"),
            ("Reviewed Documentation", "documentation")
        ]
        
        for (index, (title, type)) in activities.enumerated() {
            let activity = UserActivity(context: context)
            activity.id = UUID()
            activity.title = title
            activity.type = type
            activity.date = Date().addingTimeInterval(Double(-index * 3600)) // Hours ago
        }
        
        try? context.save()
    }
}