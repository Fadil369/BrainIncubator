import Foundation
import CoreML
import CreateML

enum LearningStyle {
    case visual
    case practical
    case theoretical
    case interactive
}

struct TrainingPattern {
    let preferredTimeOfDay: Date
    let averageSessionDuration: TimeInterval
    let completionRate: Double
    let learningStyle: LearningStyle
    let strengths: [String]
    let weaknesses: [String]
}

class SmartTrainingManager {
    static let shared = SmartTrainingManager()
    
    private var learningPatternModel: MLLinearRegressor?
    private let modelURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("learning_pattern.mlmodel")
    
    private init() {
        setupMLModel()
    }
    
    private func setupMLModel() {
        // Initialize or load existing model
        if FileManager.default.fileExists(atPath: modelURL.path) {
            do {
                learningPatternModel = try MLLinearRegressor(contentsOf: modelURL)
            } catch {
                print("Error loading model: \(error)")
                createNewModel()
            }
        } else {
            createNewModel()
        }
    }
    
    private func createNewModel() {
        // Create initial model with basic parameters
        let configuration = MLLinearRegressor.ModelParameters(
            validationData: nil,
            maxIterations: 20,
            randomSeed: 42
        )
        
        learningPatternModel = try? MLLinearRegressor(parameters: configuration)
    }
    
    func analyzeUserPattern(userId: String) -> TrainingPattern {
        // Analyze user's historical data
        let calendar = Calendar.current
        let historicalData = CoreDataManager.shared.fetchTrainingHistory(for: userId)
        
        // Calculate preferred time of day
        let completionTimes = historicalData.compactMap { $0.completedAt }
        let preferredTime = findPreferredTimeOfDay(from: completionTimes)
        
        // Calculate average session duration
        let durations = historicalData.compactMap { session -> TimeInterval? in
            guard let start = session.startedAt, let end = session.completedAt else { return nil }
            return end.timeIntervalSince(start)
        }
        let avgDuration = durations.isEmpty ? 1800 : durations.reduce(0, +) / Double(durations.count)
        
        // Calculate completion rate
        let completionRate = Double(historicalData.filter { $0.completedAt != nil }.count) / Double(historicalData.count)
        
        // Determine learning style based on module interaction patterns
        let learningStyle = determineLearningStyle(from: historicalData)
        
        // Analyze strengths and weaknesses
        let (strengths, weaknesses) = analyzePerformanceAreas(from: historicalData)
        
        return TrainingPattern(
            preferredTimeOfDay: preferredTime,
            averageSessionDuration: avgDuration,
            completionRate: completionRate,
            learningStyle: learningStyle,
            strengths: strengths,
            weaknesses: weaknesses
        )
    }
    
    func getRecommendedModules(based pattern: TrainingPattern) -> [String] {
        // Use ML model to predict most suitable modules
        let incompleteModules = CoreDataManager.shared.fetchIncompleteModules()
        
        // Score each module based on user's pattern
        let scoredModules = incompleteModules.map { module -> (String, Double) in
            let score = calculateModuleScore(module: module, pattern: pattern)
            return (module.id, score)
        }
        
        // Return IDs of top 3 recommended modules
        return scoredModules
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }
    
    private func findPreferredTimeOfDay(from times: [Date]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Default to 9 AM if no data
        if times.isEmpty {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        }
        
        // Find the most common hour
        let hours = times.map { calendar.component(.hour, from: $0) }
        let mostCommonHour = hours.reduce(into: [:]) { counts, hour in
            counts[hour, default: 0] += 1
        }.max { $0.value < $1.value }?.key ?? 9
        
        return calendar.date(bySettingHour: mostCommonHour, minute: 0, second: 0, of: now) ?? now
    }
    
    private func determineLearningStyle(from history: [TrainingProgress]) -> LearningStyle {
        // Analyze interaction patterns to determine learning style
        // This is a simplified version - would be more sophisticated in production
        let completionTimes = history.compactMap { $0.completedAt?.timeIntervalSince($0.startedAt ?? Date()) }
        let avgCompletionTime = completionTimes.reduce(0, +) / Double(completionTimes.count)
        
        if avgCompletionTime < 1200 { // Less than 20 minutes
            return .practical
        } else if avgCompletionTime < 2400 { // Less than 40 minutes
            return .visual
        } else if avgCompletionTime < 3600 { // Less than 60 minutes
            return .interactive
        } else {
            return .theoretical
        }
    }
    
    private func analyzePerformanceAreas(from history: [TrainingProgress]) -> (strengths: [String], weaknesses: [String]) {
        var moduleScores: [String: Double] = [:]
        
        // Calculate average scores for each module category
        for progress in history {
            let moduleType = progress.moduleId?.components(separatedBy: "-").first ?? ""
            let score = progress.progress
            moduleScores[moduleType, default: 0] += score
        }
        
        // Normalize scores
        let totalEntries = Double(history.count)
        moduleScores = moduleScores.mapValues { $0 / totalEntries }
        
        // Categorize as strengths (>0.7) and weaknesses (<0.4)
        let strengths = moduleScores.filter { $0.value > 0.7 }.map { $0.key }
        let weaknesses = moduleScores.filter { $0.value < 0.4 }.map { $0.key }
        
        return (strengths, weaknesses)
    }
    
    private func calculateModuleScore(module: TrainingModule, pattern: TrainingPattern) -> Double {
        var score = 1.0
        
        // Adjust score based on learning style match
        if module.type == pattern.learningStyle {
            score *= 1.5
        }
        
        // Boost score for modules addressing weaknesses
        if pattern.weaknesses.contains(module.category) {
            score *= 1.3
        }
        
        // Consider completion rate
        score *= (1 + pattern.completionRate)
        
        return score
    }
    
    func updateModel(with completedModule: TrainingProgress) {
        // Update ML model with new training data
        // This would be more sophisticated in production
        do {
            try learningPatternModel?.write(to: modelURL)
        } catch {
            print("Error updating model: \(error)")
        }
    }
}