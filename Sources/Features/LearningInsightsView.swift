import SwiftUI
import Charts

struct LearningInsightsView: View {
    let pattern: TrainingPattern?
    @StateObject private var viewModel = TrainingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let pattern = pattern {
                        // Learning Style Card
                        InsightCard("Your Learning Style") {
                            LearningStyleView(style: pattern.learningStyle)
                        }
                        
                        // Progress Overview
                        InsightCard("Weekly Progress") {
                            WeeklyProgressChart(viewModel: viewModel)
                        }
                        
                        // Learning Patterns
                        InsightCard("Learning Patterns") {
                            VStack(alignment: .leading, spacing: 16) {
                                OptimalTimeView(preferredTime: pattern.preferredTimeOfDay)
                                SessionDurationView(avgDuration: pattern.averageSessionDuration)
                            }
                        }
                        
                        // Skills Matrix
                        InsightCard("Skills Matrix") {
                            SkillsMatrixView(strengths: pattern.strengths, 
                                          weaknesses: pattern.weaknesses)
                        }
                        
                        // Recommendations
                        if !viewModel.recommendedModules.isEmpty {
                            InsightCard("Personalized Recommendations") {
                                RecommendationsView(modules: viewModel.recommendedModules)
                            }
                        }
                    } else {
                        EmptyInsightsView()
                    }
                }
                .padding()
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationTitle("Learning Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LearningStyleView: View {
    let style: LearningStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(Theme.primaryOrange)
                
                Text(style.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var iconName: String {
        switch style {
        case .visual: return "eye.fill"
        case .practical: return "hammer.fill"
        case .theoretical: return "book.fill"
        case .interactive: return "person.2.fill"
        }
    }
    
    private var description: String {
        switch style {
        case .visual:
            return "You learn best through visual aids and diagrams. We'll prioritize modules with visual content."
        case .practical:
            return "You excel with hands-on practice. We'll focus on interactive exercises and real-world applications."
        case .theoretical:
            return "You prefer understanding underlying concepts. We'll provide in-depth theoretical content."
        case .interactive:
            return "You thrive in collaborative learning. We'll emphasize interactive modules and group exercises."
        }
    }
}

struct WeeklyProgressChart: View {
    @ObservedObject var viewModel: TrainingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Chart {
                ForEach(viewModel.weeklyProgressData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.hours)
                    )
                    .foregroundStyle(Theme.primaryOrange.gradient)
                }
            }
            .frame(height: 200)
            
            // Legend
            HStack {
                Circle()
                    .fill(Theme.primaryOrange)
                    .frame(width: 8, height: 8)
                
                Text("Study Hours")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

struct OptimalTimeView: View {
    let preferredTime: Date
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(Theme.primaryOrange)
            
            VStack(alignment: .leading) {
                Text("Best Time to Study")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                Text(preferredTime, style: .time)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }
}

struct SessionDurationView: View {
    let avgDuration: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .foregroundColor(Theme.primaryOrange)
            
            VStack(alignment: .leading) {
                Text("Optimal Session Length")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                Text(formattedDuration)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }
    
    private var formattedDuration: String {
        let minutes = Int(avgDuration / 60)
        return "\(minutes) minutes"
    }
}

struct SkillsMatrixView: View {
    let strengths: [String]
    let weaknesses: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Strengths
            VStack(alignment: .leading, spacing: 8) {
                Text("Strengths")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(strengths, id: \.self) { strength in
                        Text(strength)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Areas for Improvement
            VStack(alignment: .leading, spacing: 8) {
                Text("Areas for Improvement")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(weaknesses, id: \.self) { weakness in
                        Text(weakness)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.primaryOrange.opacity(0.2))
                            .foregroundColor(Theme.primaryOrange)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct RecommendationsView: View {
    let modules: [TrainingModule]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(modules) { module in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Theme.primaryOrange)
                        .frame(width: 8, height: 8)
                    
                    Text(module.title)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(module.duration)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary)
            
            Text("Complete More Modules")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            Text("We'll analyze your learning patterns as you progress through the training modules.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceDark)
        .cornerRadius(12)
    }
}