import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Theme.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.primaryOrange)
                
                Text("BrainIncubator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                
                Text("ICD-11 Transition Made Easy")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}