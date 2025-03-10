import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            AssessmentView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Assessment")
                }
                .tag(1)
            
            TrainingView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Training")
                }
                .tag(2)
            
            DocumentationView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Docs")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(Theme.primaryOrange)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}