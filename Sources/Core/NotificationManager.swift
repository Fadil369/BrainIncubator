import UserNotifications
import SwiftUI

enum NotificationType {
    case trainingReminder
    case assessmentReminder
    case learningInsight
    case smartSuggestion
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleSmartReminder(for module: TrainingModule, at preferredTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Continue Learning"
        content.body = "Now is your optimal time to work on '\(module.title)'"
        content.sound = .default
        content.userInfo = ["moduleId": module.id]
        
        // Create calendar components for the preferred time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: preferredTime)
        components.second = 0
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "smart-reminder-\(module.id)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling smart reminder: \(error)")
            }
        }
    }
    
    func scheduleLearningInsight(pattern: TrainingPattern) {
        let content = UNMutableNotificationContent()
        content.title = "Learning Insight Available"
        
        // Customize message based on learning pattern
        if pattern.completionRate > 0.7 {
            content.body = "Great progress! Check out your learning insights and see where you excel."
        } else {
            content.body = "We've analyzed your learning style. View insights to optimize your training."
        }
        
        content.sound = .default
        
        // Schedule for next day at user's preferred time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: pattern.preferredTimeOfDay)
        components.second = 0
        
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            components.day = calendar.component(.day, from: tomorrow)
            components.month = calendar.component(.month, from: tomorrow)
            components.year = calendar.component(.year, from: tomorrow)
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "learning-insight-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling learning insight: \(error)")
            }
        }
    }
    
    func scheduleTrainingReminder(moduleTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Continue Your Training"
        content.body = "Don't forget to complete '\(moduleTitle)'"
        content.sound = .default
        
        // Schedule for tomorrow at 10 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "training-\(moduleTitle)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling training reminder: \(error)")
            }
        }
    }
    
    func scheduleSmartSuggestion(recommendedModules: [TrainingModule], pattern: TrainingPattern) {
        guard let nextModule = recommendedModules.first else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Personalized Learning Suggestion"
        content.body = "Based on your learning style, we recommend: '\(nextModule.title)'"
        content.sound = .default
        
        // Schedule at user's preferred time
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: pattern.preferredTimeOfDay)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "smart-suggestion-\(nextModule.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling smart suggestion: \(error)")
            }
        }
    }
    
    func scheduleAssessmentReminder(assessmentTitle: String, daysFromNow: Int = 3) {
        let content = UNMutableNotificationContent()
        content.title = "ICD-11 Assessment Due"
        content.body = "It's time to complete your '\(assessmentTitle)' assessment"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: Date())
        dateComponents.day! += daysFromNow
        dateComponents.hour = 14 // 2 PM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "assessment-\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWeeklyProgressReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly ICD-11 Progress Check"
        content.body = "Review your transition progress and plan next steps"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9 // 9 AM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-progress", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for type: NotificationType) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request -> String? in
                switch type {
                case .trainingReminder:
                    return request.identifier.hasPrefix("training-") ? request.identifier : nil
                case .smartSuggestion:
                    return request.identifier.hasPrefix("smart-suggestion-") ? request.identifier : nil
                case .learningInsight:
                    return request.identifier.hasPrefix("learning-insight-") ? request.identifier : nil
                case .smartReminder:
                    return request.identifier.hasPrefix("smart-reminder-") ? request.identifier : nil
                case .assessmentReminder:
                    return request.identifier.hasPrefix("assessment-") ? request.identifier : nil
                }
            }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
}