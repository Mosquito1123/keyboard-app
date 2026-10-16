import Foundation

/// Identifiers this project signs with. They match `project.yml`, the Xcode
/// build settings, and the App Group entitlement files.
public enum AppIdentity {
    public static let displayName = "键盘项目"
    public static let englishName = "KeyboardApp"
    public static let releaseVersion = "0.5.0"

    public static let appBundleIdentifier = "com.mosquito1123.keyboardapp"
    public static let keyboardBundleIdentifier = "com.mosquito1123.keyboardapp.keyboard"
    public static let appGroupIdentifier = "group.com.mosquito1123.keyboardapp"

    /// Reserved. The app does not open this URL. Dictation stays inside the current process.
    public static let urlScheme = "keyboardapp"

    /// Info.plist key expanded from the `KEYBOARD_APP_GROUP_ENABLED` build setting.
    /// `NO` forces in-process preferences so a free Personal Team can still run.
    public static let appGroupEnabledInfoKey = "KeyboardAppGroupEnabled"
}

/// Whether the system keyboard list contains this extension.
/// The containing app reads `AppleKeyboards`. The extension does not need to.
public enum KeyboardInstallStatus {
    public static func isListed(_ identifiers: [String], bundleIdentifier: String) -> Bool {
        let needle = bundleIdentifier.lowercased()
        return identifiers.contains { entry in
            let value = entry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return value == needle || value.hasPrefix(needle + ".") || value.hasPrefix(needle + " ")
        }
    }
}

/// Shipping policy. These stay false: there is no analytics SDK, no StoreKit product, and no ad SDK.
public enum ProductPolicy {
    public static let trackingEnabled = false
    public static let purchasesEnabled = false
    public static let advertisingEnabled = false
    /// Audio is never retried against a recognition server.
    public static let serverSpeechFallbackEnabled = false
    /// GPL runtimes are not linked, even as an optional download.
    public static let bundlesWhisperKit = false
    public static let bundlesLlamaRuntime = false
}
