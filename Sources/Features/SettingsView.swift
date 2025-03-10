import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("weeklyRemindersEnabled") private var weeklyRemindersEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true
    @State private var showingNotificationAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications").foregroundColor(Theme.textSecondary)) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        Toggle("Weekly Progress Reminders", isOn: $weeklyRemindersEnabled)
                            .onChange(of: weeklyRemindersEnabled) { enabled in
                                if enabled {
                                    NotificationManager.shared.scheduleWeeklyProgressReminder()
                                }
                            }
                    }
                }
                
                Section(header: Text("Appearance").foregroundColor(Theme.textSecondary)) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("About").foregroundColor(Theme.textSecondary)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: HelpSupportView()) {
                        Text("Help & Support")
                    }
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .alert("Notifications Disabled", isPresented: $showingNotificationAlert) {
                Button("Open Settings", role: .none) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                        AnalyticsManager.shared.trackUserAction(
                            action: "open_system_settings",
                            parameters: ["reason": "enable_notifications"]
                        )
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive important updates about your ICD-11 transition progress.")
            }
            .onAppear {
                AnalyticsManager.shared.trackScreenView(screenName: "Settings")
            }
            .onChange(of: notificationsEnabled) { enabled in
                AnalyticsManager.shared.trackUserAction(
                    action: "toggle_notifications",
                    parameters: ["enabled": enabled]
                )
            }
            .onChange(of: weeklyRemindersEnabled) { enabled in
                AnalyticsManager.shared.trackUserAction(
                    action: "toggle_weekly_reminders",
                    parameters: ["enabled": enabled]
                )
            }
            .onChange(of: darkModeEnabled) { enabled in
                AnalyticsManager.shared.trackUserAction(
                    action: "toggle_dark_mode",
                    parameters: ["enabled": enabled]
                )
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    showingNotificationAlert = true
                    AnalyticsManager.shared.trackUserAction(
                        action: "notification_permission_denied"
                    )
                } else {
                    NotificationManager.shared.requestAuthorization()
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Your privacy is important to us. This app collects and stores your training and assessment progress locally on your device. No personal information is collected or shared with third parties.")
                    .foregroundColor(Theme.textPrimary)
                
                Text("Data Storage")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Text("• Training progress\n• Assessment results\n• Notification preferences")
                    .foregroundColor(Theme.textPrimary)
            }
            .padding()
        }
        .background(Theme.darkBackground)
    }
}

struct HelpSupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help & Support")
                    .font(.title)
                    .foregroundColor(Theme.textPrimary)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Frequently Asked Questions")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    FAQItem(
                        question: "How do I track my progress?",
                        answer: "Your progress is automatically tracked as you complete training modules and assessments. View your overall progress on the Home screen."
                    )
                    
                    FAQItem(
                        question: "How do notifications work?",
                        answer: "The app sends reminders for incomplete training modules and assessments. You can customize notification settings in the Settings menu."
                    )
                    
                    FAQItem(
                        question: "Can I reset my progress?",
                        answer: "Contact support to reset your progress. This action cannot be undone."
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Support")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@brainincubator.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Email Support")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryOrange)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Theme.darkBackground)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(question)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.primaryOrange)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .foregroundColor(Theme.textSecondary)
                    .font(.subheadline)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Theme.surfaceDark)
        .cornerRadius(10)
    }
}