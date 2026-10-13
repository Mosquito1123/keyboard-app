import Foundation

/// App Group container shared by the containing app and the keyboard extension.
/// `PreferenceStore` reads and writes this suite. A free Personal Team often
/// cannot provision the group; see the README.
public enum SharedStore {
    public static func defaults() -> UserDefaults? {
        UserDefaults(suiteName: AppIdentity.appGroupIdentifier)
    }
}
