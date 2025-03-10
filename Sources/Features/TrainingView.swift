import SwiftUI
import Charts

struct TrainingView: View {
    @StateObject private var viewModel = TrainingViewModel()
    @State private var searchText = ""
    @State private var selectedModule: TrainingModule?
    @State private var showingInsights = false
    
    var filteredModules: [TrainingModule] {
        if searchText.isEmpty {
            return viewModel.modules
        }
        return viewModel.modules.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Smart Recommendations Section
                    if !viewModel.recommendedModules.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended for You")
                                .font(.title2)
                                .foregroundColor(Theme.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recommendedModules) { module in
                                        RecommendedModuleCard(
                                            module: module,
                                            isAccessible: viewModel.isModuleAccessible(module)
                                        )
                                        .onTapGesture {
                                            if viewModel.isModuleAccessible(module) {
                                                selectedModule = module
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Learning Insights Button
                    Button(action: { showingInsights = true }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("View Learning Insights")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Theme.primaryOrange)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("Search modules...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Theme.textPrimary)
                            .accessibilityLabel("Search training modules")
                    }
                    .padding()
                    .background(Theme.surfaceDark)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // All Modules
                    LazyVStack(spacing: 16) {
                        if filteredModules.isEmpty {
                            Text("No modules found")
                                .foregroundColor(Theme.textSecondary)
                                .padding()
                        } else {
                            ForEach(filteredModules) { module in
                                TrainingModuleCard(
                                    module: module,
                                    isAccessible: viewModel.isModuleAccessible(module)
                                )
                                .onTapGesture {
                                    if viewModel.isModuleAccessible(module) {
                                        selectedModule = module
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationTitle("Training")
            .sheet(item: $selectedModule) { module in
                ModuleDetailView(module: module, viewModel: viewModel)
            }
            .sheet(isPresented: $showingInsights) {
                LearningInsightsView(pattern: viewModel.learningPattern)
            }
            .onAppear {
                AnalyticsManager.shared.trackScreenView(screenName: "Training")
                viewModel.updateRecommendations()
            }
        }
    }
}

struct TrainingModule: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let progress: Double
}

struct ModuleDetailView: View {
    let module: TrainingModule
    let viewModel: TrainingViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(module.title)
                        .font(.title)
                        .foregroundColor(Theme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        ProgressView(value: module.progress)
                            .accentColor(Theme.primaryOrange)
                            .accessibilityLabel("Module progress")
                            .accessibilityValue("\(Int(module.progress * 100)) percent complete")
                        
                        Text("\(Int(module.progress * 100))% Complete")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Module progress \(Int(module.progress * 100)) percent")
                    
                    Button(action: {
                        let newProgress = min(1.0, module.progress + 0.2)
                        viewModel.updateProgress(for: module.id, progress: newProgress)
                        if newProgress >= 1.0 {
                            presentationMode.wrappedValue.dismiss()
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
                    .accessibilityHint(module.progress >= 1.0 ? "Module already completed" : "Double tap to continue module")
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .accessibilityLabel("Close module details"))
            .background(Theme.darkBackground.ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            AnalyticsManager.shared.trackUserAction(
                action: "view_module_details",
                parameters: ["moduleId": module.id, "moduleTitle": module.title]
            )
        }
    }
}

struct TrainingModuleCard: View {
    let module: TrainingModule
    let isAccessible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(module.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Text(module.duration)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            
            ProgressView(value: module.progress)
                .accentColor(Theme.primaryOrange)
            
            HStack {
                Text("\(Int(module.progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Image(systemName: module.progress >= 1.0 ? "checkmark.circle.fill" : "play.fill")
                    .foregroundColor(Theme.primaryOrange)
            }
        }
        .padding()
        .background(Theme.surfaceDark)
        .cornerRadius(12)
        .padding(.horizontal)
        .opacity(isAccessible ? 1 : 0.6)
    }
}

struct RecommendedModuleCard: View {
    let module: TrainingModule
    let isAccessible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(module.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(module.duration)
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryOrange)
                }
                
                Spacer()
                
                if !isAccessible {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            // Skills Tags
            FlowLayout(spacing: 4) {
                ForEach(module.skills.prefix(2), id: \.self) { skill in
                    Text(skill)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.primaryOrange.opacity(0.2))
                        .foregroundColor(Theme.primaryOrange)
                        .cornerRadius(4)
                }
            }
            
            // Progress Bar
            ProgressView(value: module.progress)
                .accentColor(Theme.primaryOrange)
        }
        .padding()
        .frame(width: 280)
        .background(Theme.surfaceDark)
        .cornerRadius(12)
        .opacity(isAccessible ? 1 : 0.6)
    }
}

struct LearningInsightsView: View {
    let pattern: TrainingPattern?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let pattern = pattern {
                        // Learning Style
                        InsightCard(title: "Your Learning Style") {
                            Text(pattern.learningStyle.description)
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        // Completion Pattern
                        InsightCard(title: "Best Training Time") {
                            Text(pattern.preferredTimeOfDay, style: .time)
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        // Strengths
                        InsightCard(title: "Your Strengths") {
                            FlowLayout(spacing: 8) {
                                ForEach(pattern.strengths, id: \.self) { strength in
                                    Text(strength.capitalized)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Areas for Improvement
                        InsightCard(title: "Areas for Improvement") {
                            FlowLayout(spacing: 8) {
                                ForEach(pattern.weaknesses, id: \.self) { weakness in
                                    Text(weakness.capitalized)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Theme.primaryOrange.opacity(0.2))
                                        .foregroundColor(Theme.primaryOrange)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Progress Chart
                        InsightCard(title: "Progress Timeline") {
                            Chart {
                                // Sample data - replace with actual progress data
                                ForEach(0..<7) { day in
                                    LineMark(
                                        x: .value("Day", "Day \(day + 1)"),
                                        y: .value("Progress", Double.random(in: 0...1))
                                    )
                                    .foregroundStyle(Theme.primaryOrange)
                                }
                            }
                            .frame(height: 200)
                        }
                    } else {
                        Text("Complete more modules to see your learning insights")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding()
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationTitle("Learning Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeViews(in: bounds, rows: rows)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var currentRow: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        var currentX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > (proposal.width ?? .infinity) {
                rows.append(currentRow)
                currentRow = [subview]
                currentX = size.width + spacing
            } else {
                currentRow.append(subview)
                currentX += size.width + spacing
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var width: CGFloat = 0
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (height > 0 ? spacing : 0)
            width = max(width, row.map { $0.sizeThatFits(.unspecified).width }.reduce(0) { $0 + $1 + spacing })
        }
        
        return CGSize(width: width, height: height)
    }
    
    private func placeViews(in bounds: CGRect, rows: [[LayoutSubviews.Element]]) {
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
}