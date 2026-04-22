import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(DependencyContainer.self) private var container
    @Query private var babies: [Baby]
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if babies.isEmpty || showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else {
                MainTabView()
            }
        }
        .onAppear {
            showOnboarding = babies.isEmpty
        }
    }
}
