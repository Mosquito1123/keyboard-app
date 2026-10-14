import Foundation

/// Placeholder identifiers. Change these together with the Xcode build settings
/// and the App Group entitlement before you ship.
public enum AppIdentity {
    public static let displayName = "键盘项目"
    public static let englishName = "KeyboardApp"
    public static let releaseVersion = "0.3.0"

    public static let appBundleIdentifier = "com.example.keyboardapp"
    public static let keyboardBundleIdentifier = "com.example.keyboardapp.keyboard"
    public static let appGroupIdentifier = "group.com.example.keyboardapp"

    /// Reserved. The app does not open this URL. Dictation stays inside the current process.
    public static let urlScheme = "keyboardapp"
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
