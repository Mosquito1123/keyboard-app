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
            .preferredColorScheme(.dark)
            .tint(Theme.mic.color)
        }
    }
}
