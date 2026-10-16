import KeyboardShared
import SwiftUI

@main
struct KeyboardApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingView()
            }
            .environmentObject(model)
            .tint(Theme.mic.color)
        }
    }
}
