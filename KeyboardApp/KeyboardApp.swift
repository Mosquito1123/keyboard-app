import KeyboardShared
import SwiftUI

@main
struct KeyboardApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .preferredColorScheme(.dark)
        }
    }
}
