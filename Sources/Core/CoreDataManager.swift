import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BrainIncubator")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Activity Tracking
    
    func logActivity(title: String, type: String) {
        let activity = Activity(context: container.viewContext)
        activity.id = UUID()
        activity.title = title
        activity.type = type
        activity.timestamp = Date()
        
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving activity: \(error)")
        }
    }
    
    func fetchRecentActivities(limit: Int = 10) -> [UserActivity] {
        let context = container.viewContext
        let request: NSFetchRequest<UserActivity> = UserActivity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserActivity.date, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent activities: \(error)")
            return []
        }
    }
    
    // MARK: - Progress Management
    
    func fetchTrainingProgress(for moduleId: String) -> TrainingProgress? {
        let request: NSFetchRequest<TrainingProgress> = TrainingProgress.fetchRequest()
        request.predicate = NSPredicate(format: "moduleId == %@", moduleId)
        
        do {
            return try container.viewContext.fetch(request).first
        } catch {
            print("Error fetching training progress: \(error)")
            return nil
        }
    }
    
    func fetchTrainingHistory(for userId: String) -> [TrainingProgress] {
        let request: NSFetchRequest<TrainingProgress> = TrainingProgress.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching training history: \(error)")
            return []
        }
    }
    
    func fetchIncompleteModules() -> [TrainingModule] {
        let request: NSFetchRequest<TrainingProgress> = TrainingProgress.fetchRequest()
        request.predicate = NSPredicate(format: "progress < 1.0")
        
        do {
            let progressRecords = try container.viewContext.fetch(request)
            let moduleIds = progressRecords.compactMap { $0.moduleId }
            return moduleIds.compactMap { moduleId in
                TrainingViewModel().modules.first { $0.id == moduleId }
            }
        } catch {
            print("Error fetching incomplete modules: \(error)")
            return []
        }
    }
    
    func fetchAssessmentProgress(for itemId: String) -> AssessmentProgress? {
        let context = container.viewContext
        let request: NSFetchRequest<AssessmentProgress> = AssessmentProgress.fetchRequest()
        request.predicate = NSPredicate(format: "itemId == %@", itemId)
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching assessment progress: \(error)")
            return nil
        }
    }
}