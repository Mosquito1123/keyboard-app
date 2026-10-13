import Foundation

/// App Group container for a future settings or transcript handoff.
/// Nothing in this skeleton reads or writes it.
public enum SharedStore {
    public static func defaults() -> UserDefaults? {
        UserDefaults(suiteName: AppIdentity.appGroupIdentifier)
    }
}
