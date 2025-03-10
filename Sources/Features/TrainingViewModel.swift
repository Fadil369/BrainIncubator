import SwiftUI
import CoreData

struct TrainingModule: Identifiable {
    let id: String
    let title: String
    let duration: String
    var progress: Double = 0.0
    let type: LearningStyle
    let category: String
    let difficulty: Int // 1-5
    let prerequisites: [String]
    let estimatedCompletionTime: TimeInterval
    let skills: [String]
}

struct WeeklyProgressData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

class TrainingViewModel: ObservableObject {
    @Published var modules: [TrainingModule] = []
    @Published var recommendedModules: [TrainingModule] = []
    @Published var learningPattern: TrainingPattern?
    @Published var weeklyProgressData: [WeeklyProgressData] = []
    private let context: NSManagedObjectContext
    
    init() {
        self.context = CoreDataManager.shared.container.viewContext
        loadModules()
        updateRecommendations()
        updateWeeklyProgress()
    }
    
    private func loadModules() {
        modules = [
            TrainingModule(
                id: "icd11-basics",
                title: "ICD-11 Basics",
                duration: "45 min",
                type: .theoretical,
                category: "fundamentals",
                difficulty: 1,
                prerequisites: [],
                estimatedCompletionTime: 2700,
                skills: ["ICD-11", "Medical Coding", "Healthcare Standards"]
            ),
            TrainingModule(
                id: "transition-guidelines",
                title: "Transition Guidelines",
                duration: "30 min",
                type: .practical,
                category: "implementation",
                difficulty: 2,
                prerequisites: ["icd11-basics"],
                estimatedCompletionTime: 1800,
                skills: ["Migration", "Process Management", "Documentation"]
            ),
            TrainingModule(
                id: "code-mapping",
                title: "Code Mapping",
                duration: "60 min",
                type: .interactive,
                category: "coding",
                difficulty: 3,
                prerequisites: ["icd11-basics", "transition-guidelines"],
                estimatedCompletionTime: 3600,
                skills: ["Code Mapping", "Clinical Terms", "Medical Terminology"]
            ),
            TrainingModule(
                id: "best-practices",
                title: "Best Practices",
                duration: "40 min",
                type: .visual,
                category: "advanced",
                difficulty: 4,
                prerequisites: ["code-mapping"],
                estimatedCompletionTime: 2400,
                skills: ["Quality Assurance", "Workflow Optimization", "Compliance"]
            )
        ]
        
        // Load progress for each module
        for (index, module) in modules.enumerated() {
            if let progress = CoreDataManager.shared.fetchTrainingProgress(for: module.id) {
                modules[index].progress = progress.progress
            }
        }
        
        scheduleReminders()
    }
    
    private func scheduleReminders() {
        for module in modules where module.progress < 1.0 {
            NotificationManager.shared.scheduleTrainingReminder(moduleTitle: module.title)
            AnalyticsManager.shared.trackTrainingProgress(moduleId: module.id, progress: module.progress)
        }
    }
    
    private func updateWeeklyProgress() {
        // Get last 7 days of training data
        guard let userId = AuthenticationManager.shared.user?.uid else { return }
        let history = CoreDataManager.shared.fetchTrainingHistory(for: userId)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var progressByDay: [Date: Double] = [:]
        
        // Group sessions by day and calculate total hours
        for progress in history {
            guard let date = progress.startedAt,
                  let endDate = progress.completedAt else { continue }
            
            let startOfDay = calendar.startOfDay(for: date)
            let duration = endDate.timeIntervalSince(date) / 3600 // Convert to hours
            progressByDay[startOfDay, default: 0] += duration
        }
        
        // Create last 7 days data
        weeklyProgressData = (0..<7).map { daysAgo -> WeeklyProgressData in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let hours = progressByDay[date] ?? 0
            let dayName = Self.dayFormatter.string(from: date)
            return WeeklyProgressData(day: dayName, hours: hours)
        }.reversed()
        
        // Schedule notifications based on patterns
        if let pattern = learningPattern {
            NotificationManager.shared.scheduleSmartSuggestion(
                recommendedModules: recommendedModules,
                pattern: pattern
            )
            NotificationManager.shared.scheduleLearningInsight(pattern: pattern)
        }
    }
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    func updateProgress(for moduleId: String, progress: Double) {
        let request: NSFetchRequest<TrainingProgress> = TrainingProgress.fetchRequest()
        request.predicate = NSPredicate(format: "moduleId == %@", moduleId)
        
        do {
            let results = try context.fetch(request)
            let progressEntity: TrainingProgress
            
            if let existing = results.first {
                progressEntity = existing
            } else {
                progressEntity = TrainingProgress(context: context)
                progressEntity.id = UUID()
                progressEntity.moduleId = moduleId
                progressEntity.startedAt = Date()
                progressEntity.userId = AuthenticationManager.shared.user?.uid
                
                // Schedule a reminder when starting a new module
                if let module = modules.first(where: { $0.id == moduleId }) {
                    NotificationManager.shared.scheduleTrainingReminder(moduleTitle: module.title)
                    AnalyticsManager.shared.trackUserAction(
                        action: "start_training_module",
                        parameters: ["moduleId": moduleId, "moduleTitle": module.title]
                    )
                }
            }
            
            progressEntity.progress = progress
            if progress >= 1.0 {
                progressEntity.completedAt = Date()
                
                if let module = modules.first(where: { $0.id == moduleId }) {
                    // Log completion activity
                    CoreDataManager.shared.logActivity(
                        title: "Completed \(module.title)",
                        type: ActivityType.training.rawValue
                    )
                    AnalyticsManager.shared.trackTrainingProgress(moduleId: moduleId, progress: 1.0)
                    
                    // Update ML model
                    SmartTrainingManager.shared.updateModel(with: progressEntity)
                    updateRecommendations()
                }
            } else {
                // Log progress activity
                if let module = modules.first(where: { $0.id == moduleId }) {
                    CoreDataManager.shared.logActivity(
                        title: "Made progress in \(module.title)",
                        type: ActivityType.training.rawValue
                    )
                    AnalyticsManager.shared.trackTrainingProgress(moduleId: moduleId, progress: progress)
                }
            }
            
            try context.save()
            
            if let index = modules.firstIndex(where: { $0.id == moduleId }) {
                modules[index].progress = progress
            }
            
            updateWeeklyProgress()
            
        } catch {
            print("Error saving progress: \(error)")
            AnalyticsManager.shared.trackError(error, context: "TrainingViewModel.updateProgress")
        }
    }
    
    func updateRecommendations() {
        guard let userId = AuthenticationManager.shared.user?.uid else { return }
        
        // Analyze user's learning pattern
        let pattern = SmartTrainingManager.shared.analyzeUserPattern(userId: userId)
        
        // Get recommended module IDs
        let recommendedIds = SmartTrainingManager.shared.getRecommendedModules(based: pattern)
        
        // Update recommended modules
        recommendedModules = modules.filter { recommendedIds.contains($0.id) }
        learningPattern = pattern
        
        objectWillChange.send()
    }
    
    func getNextRecommendedModule() -> TrainingModule? {
        return recommendedModules.first { $0.progress < 1.0 }
    }
    
    func isModuleAccessible(_ module: TrainingModule) -> Bool {
        return module.prerequisites.allSatisfy { prerequisiteId in
            modules.first { $0.id == prerequisiteId }?.progress == 1.0
        }
    }
}