import Foundation

public enum SpeechStubError: Error, Equatable, Sendable {
    /// No recognizer, audio engine, or microphone session exists in this build.
    case notImplemented
}

/// Placeholder for a future on-device recognizer.
///
/// This type never opens an audio session. Apple does not publicly guarantee
/// microphone access inside a custom keyboard extension, even after the user
/// turns on Allow Full Access. Confirm that on a device before replacing the
/// stub. If the extension cannot record, capture in the containing app and
/// pass text back through the App Group (`SharedStore`).
public struct SpeechRecognizerStub: Sendable {
    public init() {}

    public func statusLine(hasFullAccess: Bool) -> String {
        let access = hasFullAccess
            ? "完全访问已打开 · Full Access is on"
            : "完全访问未打开 · Full Access is off"
        return """
        尚未接入语音识别，麦克风不会启动。
        Speech recognition is not wired, and the microphone will not start.
        \(access)
        """
    }

    public func recognizeOnce() async throws -> String {
        throw SpeechStubError.notImplemented
    }
}
