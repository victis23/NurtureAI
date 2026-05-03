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
	@State private var showTermsAndConditions = false

    var body: some View {
        Group {
            if let container {
                Group {
                    if !appState.isAuthenticated {
						if showTermsAndConditions {
							TermsAndConditions(showTermsAndConditions: $showTermsAndConditions)
						} else {
							LoginView(showTermsAndConditions: $showTermsAndConditions)
						}
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
                                birthWeightGrams: restore.birthWeightGrams,
                                currentWeightGrams: restore.currentWeightGrams,
                                caregiverFirebaseUIDs: restore.caregiverFirebaseUIDs,
                                createdAt: restore.createdAt,
                                isFirstChild: restore.isFirstChild,
                                familySupport: restore.familySupport,
                                overwhelmLevel: restore.overwhelmLevel,
                                emotionalWellbeing: restore.emotionalWellbeing,
                                householdType: restore.householdType,
                                desiredFeatures: restore.desiredFeatures,
                                internetUsageFrequency: restore.internetUsageFrequency,
                                appDiscoverySource: restore.appDiscoverySource,
                                teethingStatus: restore.teethingStatus,
                                solidFoodStatus: restore.solidFoodStatus,
                                pediatricianVisitFrequency: restore.pediatricianVisitFrequency,
                                feedingFrequency: restore.feedingFrequency,
                                childcareChallenges: restore.childcareChallenges,
                                bathingFrequency: restore.bathingFrequency,
                                aiUsageHistory: restore.aiUsageHistory
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
	@State private var tabtapped: Int = 0

    var body: some View {
		TabView(selection: $tabtapped) {
			NavigationStack {
				HomeView()
			}
			.tabItem { Label("Today", systemImage: "sun.max") }
			.tag(0)

			NavigationStack {
				AssistView()
			}
			.tabItem { Label("Ask AI", systemImage: "bubble.left.and.bubble.right") }
			.tag(1)

			NavigationStack {
				QuickLogView()
			}
			.tabItem { Label("Log", systemImage: "plus.circle.fill") }
			.tag(2)

			NavigationStack {
				LogHistoryView()
			}
			.tabItem { Label("History", systemImage: "clock") }
			.tag(3)

			NavigationStack {
				SettingsView()
			}
			.tabItem { Label("Settings", systemImage: "gear") }
			.tag(4)
        }
        .tint(NurturColors.accent)
		.sensoryFeedback(.selection, trigger: tabtapped)
    }
}
