import SwiftUI
import CoreData

class AssessmentViewModel: ObservableObject {
    @Published var assessmentItems: [AssessmentItem] = []
    private let context: NSManagedObjectContext
    
    init() {
        self.context = CoreDataManager.shared.container.viewContext
        loadAssessments()
    }
    
    private func loadAssessments() {
        // Initial assessment items
        assessmentItems = [
            AssessmentItem(id: "self-assessment-1", title: "ICD-11 Knowledge", category: "Self-Assessment"),
            AssessmentItem(id: "self-assessment-2", title: "Transition Readiness", category: "Self-Assessment"),
            AssessmentItem(id: "team-assessment-1", title: "Team Competency", category: "Team Assessment"),
            AssessmentItem(id: "team-assessment-2", title: "Workflow Integration", category: "Team Assessment"),
            AssessmentItem(id: "org-assessment-1", title: "Infrastructure Review", category: "Organization Assessment"),
            AssessmentItem(id: "org-assessment-2", title: "Resource Allocation", category: "Organization Assessment")
        ]
        
        // Load progress for each assessment
        let request: NSFetchRequest<AssessmentProgress> = AssessmentProgress.fetchRequest()
        if let results = try? context.fetch(request) {
            for progress in results {
                if let index = assessmentItems.firstIndex(where: { $0.id == progress.itemId }) {
                    assessmentItems[index].score = Int(progress.score)
                    assessmentItems[index].isCompleted = progress.completedAt != nil
                }
            }
        }
        
        // Schedule reminders for incomplete assessments
        for item in assessmentItems where !item.isCompleted {
            NotificationManager.shared.scheduleAssessmentReminder(assessmentTitle: item.title)
            AnalyticsManager.shared.trackUserAction(
                action: "view_incomplete_assessment",
                parameters: [
                    "assessmentId": item.id,
                    "assessmentTitle": item.title,
                    "category": item.category
                ]
            )
        }
    }
    
    func updateAssessment(itemId: String, score: Int) {
        let request: NSFetchRequest<AssessmentProgress> = AssessmentProgress.fetchRequest()
        request.predicate = NSPredicate(format: "itemId == %@", itemId)
        
        do {
            let results = try context.fetch(request)
            let progressEntity: AssessmentProgress
            
            if let existing = results.first {
                progressEntity = existing
            } else {
                progressEntity = AssessmentProgress(context: context)
                progressEntity.id = UUID()
                progressEntity.itemId = itemId
                progressEntity.startedAt = Date()
                if let item = assessmentItems.first(where: { $0.id == itemId }) {
                    progressEntity.category = item.category
                    
                    // Track assessment start
                    AnalyticsManager.shared.trackUserAction(
                        action: "start_assessment",
                        parameters: [
                            "assessmentId": itemId,
                            "assessmentTitle": item.title,
                            "category": item.category
                        ]
                    )
                    
                    NotificationManager.shared.scheduleAssessmentReminder(assessmentTitle: item.title)
                }
            }
            
            progressEntity.score = Int16(score)
            progressEntity.completedAt = Date()
            
            if let item = assessmentItems.first(where: { $0.id == itemId }) {
                CoreDataManager.shared.logActivity(
                    title: "Completed \(item.title) Assessment",
                    type: ActivityType.assessment.rawValue
                )
                
                // Track assessment completion
                AnalyticsManager.shared.trackAssessmentCompletion(
                    assessmentId: itemId,
                    score: score
                )
            }
            
            try context.save()
            
            if let index = assessmentItems.firstIndex(where: { $0.id == itemId }) {
                assessmentItems[index].score = score
                assessmentItems[index].isCompleted = true
            }
        } catch {
            print("Error saving assessment: \(error)")
            AnalyticsManager.shared.trackError(error, context: "AssessmentViewModel.updateAssessment")
        }
    }
    
    func scheduleRemindersForIncomplete() {
        for item in assessmentItems where !item.isCompleted {
            NotificationManager.shared.scheduleAssessmentReminder(assessmentTitle: item.title)
            AnalyticsManager.shared.trackUserAction(
                action: "schedule_assessment_reminder",
                parameters: [
                    "assessmentId": item.id,
                    "assessmentTitle": item.title
                ]
            )
        }
    }
}

struct AssessmentItem: Identifiable {
    let id: String
    let title: String
    let category: String
    var score: Int = 0
    var isCompleted: Bool = false
}