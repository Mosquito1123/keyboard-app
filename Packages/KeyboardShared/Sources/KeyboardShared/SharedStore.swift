import Foundation

/// Preferences shared by the containing app and the keyboard extension.
///
/// The App Group container is used only when this process is entitled for
/// `AppIdentity.appGroupIdentifier` and the build setting
/// `KEYBOARD_APP_GROUP_ENABLED` is YES. Otherwise reads and writes stay in
/// `UserDefaults.standard` for the current process. The keyboard then keeps
/// its own defaults and does not see changes made in the app.
public enum SharedStore {
    /// True when settings written here can be read by the other process.
    public static var usesAppGroup: Bool {
        #if KEYBOARD_APP_GROUP_DISABLED
        return false
        #else
        if forcedOffByInfoPlist {
            return false
        }
        return containerURL() != nil
        #endif
    }

    /// The shared suite when the group is available. `nil` means the caller
    /// should use `UserDefaults.standard` (in-process only).
    public static func defaults() -> UserDefaults? {
        guard usesAppGroup else { return nil }
        return UserDefaults(suiteName: AppIdentity.appGroupIdentifier)
    }

    public static func containerURL() -> URL? {
        #if KEYBOARD_APP_GROUP_DISABLED
        return nil
        #elseif os(iOS) || os(macOS)
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppIdentity.appGroupIdentifier
        )
        #else
        return nil
        #endif
    }

    /// `KeyboardAppGroupEnabled` = NO in the built Info.plist. That is the
    /// default Personal Team configuration.
    private static var forcedOffByInfoPlist: Bool {
        let raw = Bundle.main.object(forInfoDictionaryKey: AppIdentity.appGroupEnabledInfoKey) as? String
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "no", "0", "false":
            return true
        default:
            return false
        }
    }
}
