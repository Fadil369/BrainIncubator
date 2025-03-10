import SwiftUI

struct DocumentationView: View {
    @State private var selectedSection = 0
    let sections = ["Guidelines", "References", "FAQs"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Section Selector
                Picker("Section", selection: $selectedSection) {
                    ForEach(0..<sections.count, id: \.self) { index in
                        Text(sections[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accessibilityLabel("Documentation section selector")
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedSection {
                        case 0:
                            GuidelinesSection()
                        case 1:
                            ReferencesSection()
                        case 2:
                            FAQSection()
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Theme.darkBackground.ignoresSafeArea())
            .navigationTitle("Documentation")
            .onAppear {
                AnalyticsManager.shared.trackScreenView(screenName: "Documentation")
            }
        }
    }
}

struct GuidelinesSection: View {
    let guidelines = [
        "Implementation Guide",
        "Coding Guidelines",
        "Transition Timeline",
        "Quality Assurance"
    ]
    
    var body: some View {
        ForEach(guidelines, id: \.self) { guideline in
            DocumentCard(
                title: guideline,
                icon: "doc.text.fill",
                action: {
                    AnalyticsManager.shared.trackUserAction(
                        action: "view_guideline",
                        parameters: ["title": guideline]
                    )
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(guideline) guideline")
            .accessibilityHint("Double tap to open guideline document")
            .accessibilityAddTraits(.isButton)
        }
    }
}

struct ReferencesSection: View {
    let references = [
        "ICD-11 Reference Manual",
        "Code Mapping Tables",
        "Clinical Examples",
        "Technical Specifications"
    ]
    
    var body: some View {
        ForEach(references, id: \.self) { reference in
            DocumentCard(
                title: reference,
                icon: "book.fill",
                action: {
                    AnalyticsManager.shared.trackUserAction(
                        action: "view_reference",
                        parameters: ["title": reference]
                    )
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(reference) reference document")
            .accessibilityHint("Double tap to open reference material")
            .accessibilityAddTraits(.isButton)
        }
    }
}

struct FAQSection: View {
    let faqs = [
        "Common Implementation Questions",
        "Technical Support Guide",
        "Training Resources FAQ",
        "Updates and Changes"
    ]
    
    var body: some View {
        ForEach(faqs, id: \.self) { faq in
            DocumentCard(
                title: faq,
                icon: "questionmark.circle.fill",
                action: {
                    AnalyticsManager.shared.trackUserAction(
                        action: "view_faq",
                        parameters: ["title": faq]
                    )
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(faq) frequently asked questions")
            .accessibilityHint("Double tap to view FAQ section")
            .accessibilityAddTraits(.isButton)
        }
    }
}

struct DocumentCard: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Theme.primaryOrange)
                    .frame(width: 44)
                    .accessibilityHidden(true)
                
                Text(title)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Theme.surfaceDark)
            .cornerRadius(12)
        }
    }
}