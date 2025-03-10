import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var trainingVM = TrainingViewModel()
    @StateObject private var assessmentVM = AssessmentViewModel()
    @State private var recentActivities: [ActivityItem] = []
    
    var overallProgress: Double {
        let trainingProgress = trainingVM.modules.map { $0.progress }.reduce(0.0, +) / Double(trainingVM.modules.count)
        let assessmentProgress = Double(assessmentVM.assessmentItems.filter { $0.isCompleted }.count) / Double(assessmentVM.assessmentItems.count)
        return (trainingProgress + assessmentProgress) / 2.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ICD-11 Transition Progress")
                            .font(.title2)
                            .foregroundColor(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        
                        ProgressView(value: overallProgress)
                            .accentColor(Theme.primaryOrange)
                            .accessibilityLabel("Overall progress")
                            .accessibilityValue("\(Int(overallProgress * 100)) percent complete")
                        
                        Text("\(Int(overallProgress * 100))% Complete")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding()
                    .background(Theme.surfaceDark)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Progress Overview")
                    
                    // Quick Actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink(destination: TrainingView()) {
                            QuickActionCard(
                                title: "Continue Training",
                                icon: "book.fill",
                                progress: trainingVM.modules.map { $0.progress }.reduce(0.0, +) / Double(trainingVM.modules.count)
                            )
                        }
                        
                        NavigationLink(destination: AssessmentView()) {
                            QuickActionCard(
                                title: "Assessment",
                                icon: "checklist",
                                progress: Double(assessmentVM.assessmentItems.filter { $0.isCompleted }.count) / Double(assessmentVM.assessmentItems.count)
                            )
                        }
                        
                        NavigationLink(destination: DocumentationView()) {
                            QuickActionCard(
                                title: "Documentation",
                                icon: "doc.text.fill",
                                progress: nil
                            )
                        }
                        
                        Button(action: { showHelpAndSupport() }) {
                            QuickActionCard(
                                title: "Help & Support",
                                icon: "questionmark.circle.fill",
                                progress: nil
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.title2)
                            .foregroundColor(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.horizontal)
                        
                        if recentActivities.isEmpty {
                            Text("No recent activities")
                                .foregroundColor(Theme.textSecondary)
                                .padding()
                                .accessibilityLabel("No recent activities available")
                        } else {
                            ForEach(recentActivities, id: \.id) { activity in
                                ActivityRow(activity: activity)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(activity.title), \(activity.type.rawValue), \(activity.date.formatted(date: .abbreviated, time: .shortened))")
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationTitle("Home")
            .onAppear {
                loadRecentActivities()
                AnalyticsManager.shared.trackScreenView(screenName: "Home")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func loadRecentActivities() {
        let coreDataActivities = CoreDataManager.shared.fetchRecentActivities()
        recentActivities = coreDataActivities.map { activity in
            ActivityItem(
                id: activity.id ?? UUID(),
                title: activity.title ?? "",
                type: ActivityType(rawValue: activity.type ?? "") ?? .documentation,
                date: activity.date ?? Date()
            )
        }
    }
    
    private func showHelpAndSupport() {
        CoreDataManager.shared.logActivity(
            title: "Accessed Help & Support",
            type: ActivityType.documentation.rawValue
        )
        AnalyticsManager.shared.trackUserAction(
            action: "access_help_support",
            parameters: ["source": "home_screen"]
        )
        // Implementation for showing help and support will go here
    }
}

// Update QuickActionCard with accessibility
struct QuickActionCard: View {
    let title: String
    let icon: String
    let progress: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.primaryOrange)
            
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            if let progress = progress {
                ProgressView(value: progress)
                    .accentColor(Theme.primaryOrange)
                    .accessibilityLabel("Progress")
                    .accessibilityValue("\(Int(progress * 100)) percent")
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .frame(height: 140)
        .background(Theme.surfaceDark)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(progress != nil ? "Progress: \(Int((progress ?? 0) * 100))%" : "")")
    }
}

struct ActivityItem: Identifiable {
    let id: UUID
    let title: String
    let type: ActivityType
    let date: Date
}

enum ActivityType: String {
    case training
    case assessment
    case documentation
    
    var iconName: String {
        switch self {
        case .training:
            return "book.fill"
        case .assessment:
            return "checklist"
        case .documentation:
            return "doc.text.fill"
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack {
            Image(systemName: activity.type.iconName)
                .foregroundColor(Theme.primaryOrange)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(activity.title)
                    .foregroundColor(Theme.textPrimary)
                Text(activity.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.surfaceDark)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}