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
    @State private var isRestoringAccount = false

    var body: some View {
        Group {
            if let container {
                Group {
                    if !appState.isAuthenticated {
                        LoginView()
                    } else if isRestoringAccount {
                        // Silently checking Firestore for an existing baby after reinstall.
                        ProgressView()
                    } else if !appState.hasCompletedOnboarding {
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
                appState.restoreAuthState()
                let c = AppContainer.live(modelContext: modelContext)
                container = c

                // Reinstall detection: authenticated but onboarding flag wiped with SwiftData.
                // Check Firestore for an existing baby before showing the onboarding flow.
                if appState.isAuthenticated,
                   !appState.hasCompletedOnboarding,
                   let uid = appState.firebaseUID {
                    isRestoringAccount = true
                    do {
                        if let restore = try await c.syncService.fetchBabyForRestore(uid: uid) {
                            let baby = Baby(
                                id: restore.id,
                                name: restore.name,
                                birthDate: restore.birthDate,
                                feedingMethod: restore.feedingMethod,
                                caregiverFirebaseUIDs: restore.caregiverFirebaseUIDs,
                                createdAt: restore.createdAt
                            )
                            try c.babyRepository.save(baby)
                            appState.hasCompletedOnboarding = true
                        }
                    } catch {
                        // Non-fatal — user will see onboarding and can re-create their profile.
                    }
                    isRestoringAccount = false
                }
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
