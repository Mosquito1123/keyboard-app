import Foundation

/// Languages this preview actually branches on.
/// The list is intentionally short: it selects demo sentences and a few
/// punctuation marks. It does not load a speech model.
public enum TypingLanguage: String, CaseIterable, Sendable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"

    public var id: String { rawValue }

    public var commaMark: String {
        switch self {
        case .simplifiedChinese:
            return "，"
        case .english:
            return ","
        case .japanese:
            return "、"
        }
    }

    public var periodMark: String {
        switch self {
        case .simplifiedChinese, .japanese:
            return "。"
        case .english:
            return "."
        }
    }

    /// Fixed sentence inserted by the demo recognizer. Not a transcription.
    public var sampleUtterance: String {
        switch self {
        case .simplifiedChinese:
            return "周五前把提纲发给我，会议改到下午三点。"
        case .english:
            return "Please send me the outline before Friday. The meeting moved to three."
        case .japanese:
            return "金曜までに概要を送ってください。会議は三時に変更です。"
        }
    }

    /// Local, deterministic stand-in for a rewrite model.
    /// Empty input becomes a canned sentence. Other input is labeled and lightly normalized.
    public func demoRewrite(of source: String) -> String {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if collapsed.isEmpty {
            switch self {
            case .simplifiedChinese:
                return "（演示润色）请在周五前把提纲发给我。"
            case .english:
                return "(demo rewrite) Please send the outline before Friday."
            case .japanese:
                return "（デモ整形）金曜までに概要を送ってください。"
            }
        }
        switch self {
        case .simplifiedChinese:
            let body = collapsed.hasSuffix("。") ? collapsed : collapsed + "。"
            return "（演示润色）\(body)"
        case .english:
            let body = collapsed.hasSuffix(".") ? collapsed : collapsed + "."
            return "(demo rewrite) \(body)"
        case .japanese:
            let body = collapsed.hasSuffix("。") ? collapsed : collapsed + "。"
            return "（デモ整形）\(body)"
        }
    }
}

public struct KeyboardPreferences: Sendable, Equatable {
    public var language: TypingLanguage
    public var demoModeEnabled: Bool

    public init(language: TypingLanguage, demoModeEnabled: Bool) {
        self.language = language
        self.demoModeEnabled = demoModeEnabled
    }

    /// Used when the keyboard cannot read the shared store (Full Access off).
    public static let builtInFallback = KeyboardPreferences(
        language: .simplifiedChinese,
        demoModeEnabled: true
    )
}

/// App Group preferences shared by the containing app and the keyboard.
/// The extension should read this only after the user allows Full Access.
public enum PreferenceStore {
    private enum Key {
        static let language = "kp.language"
        static let demoMode = "kp.demoMode"
    }

    public static func load() -> KeyboardPreferences {
        load(from: SharedStore.defaults() ?? .standard)
    }

    public static func save(_ preferences: KeyboardPreferences) {
        save(preferences, to: SharedStore.defaults() ?? .standard)
    }

    public static func load(from defaults: UserDefaults) -> KeyboardPreferences {
        let language = defaults.string(forKey: Key.language).flatMap(TypingLanguage.init(rawValue:))
            ?? KeyboardPreferences.builtInFallback.language
        let demoModeEnabled: Bool
        if defaults.object(forKey: Key.demoMode) == nil {
            demoModeEnabled = KeyboardPreferences.builtInFallback.demoModeEnabled
        } else {
            demoModeEnabled = defaults.bool(forKey: Key.demoMode)
        }
        return KeyboardPreferences(language: language, demoModeEnabled: demoModeEnabled)
    }

    public static func save(_ preferences: KeyboardPreferences, to defaults: UserDefaults) {
        defaults.set(preferences.language.rawValue, forKey: Key.language)
        defaults.set(preferences.demoModeEnabled, forKey: Key.demoMode)
    }
}
