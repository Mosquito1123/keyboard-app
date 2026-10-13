import KeyboardShared
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var language: TypingLanguage
    @Published private(set) var demoModeEnabled: Bool
    private let writesToSharedStore: Bool

    init(preferences: KeyboardPreferences = PreferenceStore.load(), writesToSharedStore: Bool = true) {
        language = preferences.language
        demoModeEnabled = preferences.demoModeEnabled
        self.writesToSharedStore = writesToSharedStore
    }

    func setLanguage(_ language: TypingLanguage) {
        self.language = language
        persist()
    }

    func setDemoMode(_ enabled: Bool) {
        demoModeEnabled = enabled
        persist()
    }

    private func persist() {
        guard writesToSharedStore else { return }
        PreferenceStore.save(
            KeyboardPreferences(language: language, demoModeEnabled: demoModeEnabled)
        )
    }
}
