import SwiftUI

struct MainTabView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            FeedingLogView()
                .tabItem { Label("Feeding", systemImage: "drop.fill") }

            SleepLogView()
                .tabItem { Label("Sleep", systemImage: "moon.fill") }

            DiaperLogView()
                .tabItem { Label("Diaper", systemImage: "bubbles.and.sparkles") }

            AIAssistantView()
                .tabItem { Label("Ask AI", systemImage: "sparkles") }
        }
        .tint(.purple)
    }
}
