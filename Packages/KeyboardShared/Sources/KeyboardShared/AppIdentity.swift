import Foundation

/// Placeholder identifiers. Change these together with the Xcode build settings
/// and the App Group entitlement before you ship.
public enum AppIdentity {
    public static let displayName = "键盘项目"
    public static let englishName = "KeyboardApp"
    public static let releaseVersion = "0.2.0"

    public static let appBundleIdentifier = "com.example.keyboardapp"
    public static let keyboardBundleIdentifier = "com.example.keyboardapp.keyboard"
    public static let appGroupIdentifier = "group.com.example.keyboardapp"

    /// Reserved for a future handoff from the keyboard to the containing app.
    /// The skeleton never opens this URL.
    public static let urlScheme = "keyboardapp"
}
