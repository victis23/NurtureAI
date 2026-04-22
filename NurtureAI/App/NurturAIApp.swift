import SwiftUI
import SwiftData

@main
struct NurturAIApp: App {
    @State private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
        }
        .modelContainer(for: [Baby.self, BabyLog.self, AIInsight.self])
    }
}

struct AppRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var container: AppContainer?

    var body: some View {
        Group {
            if let container {
                Group {
                    if !appState.hasCompletedOnboarding {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                }
                .environment(\.appContainer, container)
            } else {
                ProgressView()
            }
        }
        .task {
            if container == nil {
                container = AppContainer.live(modelContext: modelContext)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            AssistView()
                .tabItem { Label("Ask AI", systemImage: "bubble.left.and.bubble.right") }

            QuickLogView()
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }

            LogHistoryView()
                .tabItem { Label("History", systemImage: "clock") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(NurturColors.accent)
    }
}
