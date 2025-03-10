import SwiftUI

struct AssessmentView: View {
    @StateObject private var viewModel = AssessmentViewModel()
    @State private var selectedCategory = 0
    @State private var selectedItem: AssessmentItem?
    
    let categories = ["Self-Assessment", "Team Assessment", "Organization Assessment"]
    
    var filteredItems: [AssessmentItem] {
        viewModel.assessmentItems.filter { $0.category == categories[selectedCategory] }
    }
    
    var categoryProgress: Double {
        let items = filteredItems
        guard !items.isEmpty else { return 0.0 }
        return Double(items.filter { $0.isCompleted }.count) / Double(items.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category Selector
                Picker("Category", selection: $selectedCategory) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        Text(categories[index])
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accessibilityLabel("Assessment category selector")
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Assessment Progress
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Progress")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            
                            ProgressView(value: categoryProgress)
                                .accentColor(Theme.primaryOrange)
                                .accessibilityLabel("Assessment progress")
                                .accessibilityValue("\(Int(categoryProgress * 100)) percent complete")
                            
                            Text("\(Int(categoryProgress * 100))% Complete")
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding()
                        .background(Theme.surfaceDark)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Assessment progress for \(categories[selectedCategory])")
                        
                        // Assessment Items
                        ForEach(filteredItems) { item in
                            AssessmentItemCard(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(item.title)")
                                .accessibilityValue(item.isCompleted ? "Completed with score \(item.score)" : "Not completed")
                                .accessibilityHint(item.isCompleted ? "Assessment completed" : "Double tap to start assessment")
                                .accessibilityAddTraits(item.isCompleted ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Assessment")
            .background(Theme.darkBackground.ignoresSafeArea())
            .sheet(item: $selectedItem) { item in
                AssessmentDetailView(item: item, viewModel: viewModel)
            }
        }
    }
}

struct AssessmentItemCard: View {
    let item: AssessmentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                if item.isCompleted {
                    Text("Score: \(item.score)")
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryOrange)
                }
            }
            
            HStack {
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? Theme.primaryOrange : Theme.textSecondary)
            }
        }
        .padding()
        .background(Theme.surfaceDark)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AssessmentDetailView: View {
    let item: AssessmentItem
    let viewModel: AssessmentViewModel
    @State private var selectedScore = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.title)
                        .font(.title)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Select your score:")
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { score in
                            Button(action: {
                                selectedScore = score
                            }) {
                                Circle()
                                    .fill(selectedScore >= score ? Theme.primaryOrange : Theme.surfaceDark)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text("\(score)")
                                            .foregroundColor(selectedScore >= score ? .white : Theme.textSecondary)
                                    )
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.updateAssessment(itemId: item.id, score: selectedScore)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Submit Assessment")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryOrange)
                            .cornerRadius(10)
                    }
                    .disabled(selectedScore == 0)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Theme.darkBackground.ignoresSafeArea())
        }
    }
}