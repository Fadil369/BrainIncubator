import XCTest
@testable import BrainIncubator
import CoreData

final class CoreDataManagerTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
        context = coreDataManager.container.viewContext
    }
    
    override func tearDown() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TrainingProgress")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        super.tearDown()
    }
    
    func testSaveTrainingProgress() throws {
        // Given
        let moduleId = "test-module"
        let progress = 0.5
        let trainingProgress = TrainingProgress(context: context)
        trainingProgress.id = UUID()
        trainingProgress.moduleId = moduleId
        trainingProgress.progress = progress
        trainingProgress.startedAt = Date()
        
        // When
        try context.save()
        
        // Then
        let fetchedProgress = try XCTUnwrap(coreDataManager.fetchTrainingProgress(for: moduleId))
        XCTAssertEqual(fetchedProgress.moduleId, moduleId)
        XCTAssertEqual(fetchedProgress.progress, progress)
    }
    
    func testSaveAssessmentProgress() throws {
        // Given
        let itemId = "test-assessment"
        let category = "Self-Assessment"
        let score = Int16(80)
        let assessmentProgress = AssessmentProgress(context: context)
        assessmentProgress.id = UUID()
        assessmentProgress.itemId = itemId
        assessmentProgress.category = category
        assessmentProgress.score = score
        assessmentProgress.startedAt = Date()
        
        // When
        try context.save()
        
        // Then
        let fetchedProgress = try XCTUnwrap(coreDataManager.fetchAssessmentProgress(for: itemId))
        XCTAssertEqual(fetchedProgress.itemId, itemId)
        XCTAssertEqual(fetchedProgress.category, category)
        XCTAssertEqual(fetchedProgress.score, score)
    }
    
    func testLogAndFetchActivity() throws {
        // Given
        let title = "Test Activity"
        let type = "training"
        
        // When
        coreDataManager.logActivity(title: title, type: type)
        
        // Then
        let activities = coreDataManager.fetchRecentActivities(limit: 1)
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities.first?.title, title)
        XCTAssertEqual(activities.first?.type, type)
    }
    
    func testFetchRecentActivitiesLimit() throws {
        // Given
        for i in 0..<5 {
            coreDataManager.logActivity(title: "Activity \(i)", type: "test")
        }
        
        // When
        let activities = coreDataManager.fetchRecentActivities(limit: 3)
        
        // Then
        XCTAssertEqual(activities.count, 3)
    }
}