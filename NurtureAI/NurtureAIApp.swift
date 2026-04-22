import SwiftUI
import SwiftData

@main
struct NurtureAIApp: App {
    let container: DependencyContainer

    init() {
        container = DependencyContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .modelContainer(container.modelContainer)
        }
    }
}
