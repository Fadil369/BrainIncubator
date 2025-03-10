import SwiftUI
import FirebaseAnalytics
import FirebaseAuth

@main
struct BrainIncubatorApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    
    init() {
        FirebaseApp.configure()
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .preferredColorScheme(.dark)
                    .environment(\.colorScheme, .dark)
            } else {
                NavigationView {
                    SignInView()
                }
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
            }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.darkBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Theme.darkBackground)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure tab bar item colors
        UITabBar.appearance().unselectedItemTintColor = UIColor(Theme.textSecondary)
        UITabBar.appearance().tintColor = UIColor(Theme.primaryOrange)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending changes to Core Data
        CoreDataManager.shared.save()
    }
}