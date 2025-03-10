import SwiftUI

struct ModuleDetailView: View {
    let module: TrainingModule
    @ObservedObject var viewModel: TrainingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLearningTips = false
    @State private var timeSpent: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Module Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(module.title)
                        .font(.title)
                        .foregroundColor(Theme.textPrimary)
                    
                    HStack(spacing: 16) {
                        LearningBadge(icon: "clock.fill", text: module.duration)
                        LearningBadge(icon: "chart.bar.fill", text: "Level \(module.difficulty)")
                        LearningBadge(icon: learningStyleIcon, text: module.type.rawValue.capitalized)
                    }
                }
                
                // Smart Learning Tips
                if showingLearningTips {
                    SmartTipsCard(module: module, pattern: viewModel.learningPattern)
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    ProgressView(value: module.progress)
                        .accentColor(Theme.primaryOrange)
                    
                    HStack {
                        Text("\(Int(module.progress * 100))% Complete")
                            .foregroundColor(Theme.textSecondary)
                        
                        Spacer()
                        
                        if timeSpent > 0 {
                            Text(timeSpentFormatted)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .font(.subheadline)
                }
                
                // Skills Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skills You'll Learn")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(module.skills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.primaryOrange.opacity(0.2))
                                .foregroundColor(Theme.primaryOrange)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Prerequisites
                if !module.prerequisites.isEmpty {
                    PrerequisitesView(
                        prerequisites: module.prerequisites,
                        modules: viewModel.modules
                    )
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let newProgress = min(1.0, module.progress + 0.2)
                        viewModel.updateProgress(for: module.id, progress: newProgress)
                        if newProgress >= 1.0 {
                            timer?.invalidate()
                            timer = nil
                            dismiss()
                        }
                    }) {
                        Text(module.progress >= 1.0 ? "Completed" : "Continue Module")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryOrange)
                            .cornerRadius(10)
                    }
                    .disabled(module.progress >= 1.0)
                    
                    Button(action: { showingLearningTips.toggle() }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text(showingLearningTips ? "Hide Learning Tips" : "Show Learning Tips")
                        }
                        .foregroundColor(Theme.primaryOrange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryOrange.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Theme.darkBackground.ignoresSafeArea())
        .navigationBarItems(trailing: Button("Close") { dismiss() })
        .onAppear {
            startTracking()
            if let pattern = viewModel.learningPattern {
                NotificationManager.shared.scheduleSmartReminder(
                    for: module,
                    at: pattern.preferredTimeOfDay
                )
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private var learningStyleIcon: String {
        switch module.type {
        case .visual: return "eye.fill"
        case .practical: return "hammer.fill"
        case .theoretical: return "book.fill"
        case .interactive: return "person.2.fill"
        }
    }
    
    private var timeSpentFormatted: String {
        let minutes = Int(timeSpent / 60)
        return "\(minutes)m spent"
    }
    
    private func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeSpent += 1
        }
    }
}

struct LearningBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.surfaceDark)
        .cornerRadius(6)
        .foregroundColor(Theme.textSecondary)
    }
}

struct SmartTipsCard: View {
    let module: TrainingModule
    let pattern: TrainingPattern?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.primaryOrange)
                Text("Smart Learning Tips")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            
            if let pattern = pattern {
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(
                        icon: "clock.fill",
                        title: "Optimal Time",
                        description: "Your best learning time is around \(pattern.preferredTimeOfDay, style: .time)"
                    )
                    
                    TipRow(
                        icon: "timer",
                        title: "Session Length",
                        description: "Aim for \(Int(pattern.averageSessionDuration / 60)) minute sessions for best results"
                    )
                    
                    if pattern.learningStyle == module.type {
                        TipRow(
                            icon: "star.fill",
                            title: "Perfect Match",
                            description: "This module matches your learning style!"
                        )
                    }
                }
            } else {
                Text("Complete more modules to receive personalized tips")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .background(Theme.surfaceDark)
        .cornerRadius(12)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryOrange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

struct PrerequisitesView: View {
    let prerequisites: [String]
    let modules: [TrainingModule]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prerequisites")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(prerequisites, id: \.self) { prereqId in
                    if let module = modules.first(where: { $0.id == prereqId }) {
                        HStack {
                            Circle()
                                .fill(module.progress >= 1.0 ? Color.green : Theme.textSecondary)
                                .frame(width: 8, height: 8)
                            
                            Text(module.title)
                                .font(.subheadline)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(module.progress * 100))%")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}