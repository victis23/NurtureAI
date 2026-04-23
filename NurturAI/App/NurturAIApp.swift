import SwiftUI
import SwiftData
import FirebaseCore

@main
struct NurturAIApp: App {
    @State private var appState = AppState.shared

    init() {
        FirebaseApp.configure()
    }

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
			NavigationStack {
				HomeView()
			}
			.tabItem { Label("Today", systemImage: "sun.max") }

			NavigationStack {
				AssistView()
			}
			.tabItem { Label("Ask AI", systemImage: "bubble.left.and.bubble.right") }

			NavigationStack {
				QuickLogView()
			}
			.tabItem { Label("Log", systemImage: "plus.circle.fill") }

			NavigationStack {
				LogHistoryView()
			}
			.tabItem { Label("History", systemImage: "clock") }

			NavigationStack {
				SettingsView()
			}
			.tabItem { Label("Settings", systemImage: "gear") }     
        }
        .tint(NurturColors.accent)
    }
}
