import Foundation

public enum SpeechStubError: Error, Equatable, Sendable {
    /// No recognizer, audio engine, or microphone session exists in this build.
    case notImplemented
}

public struct RecognizedUtterance: Sendable, Equatable {
    public var text: String
    public var engineName: String
    /// True when `text` is a bundled sample, not captured speech.
    public var usedDemoFixture: Bool

    public init(text: String, engineName: String, usedDemoFixture: Bool) {
        self.text = text
        self.engineName = engineName
        self.usedDemoFixture = usedDemoFixture
    }
}

/// On-device speech entry point.
/// Implementations must not open the network. The demo engine also skips audio.
public protocol SpeechRecognizing: Sendable {
    var engineName: String { get }
    func transcribe(language: TypingLanguage) async throws -> RecognizedUtterance
}

/// Waits, then returns a language-specific sample sentence.
public struct DemoSpeechRecognizer: SpeechRecognizing {
    public var engineName: String { "demo-fixture" }
    public var delayNanoseconds: UInt64

    public init(delayNanoseconds: UInt64 = 700_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    public func transcribe(language: TypingLanguage) async throws -> RecognizedUtterance {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return RecognizedUtterance(
            text: language.sampleUtterance,
            engineName: engineName,
            usedDemoFixture: true
        )
    }
}

/// The non-demo path. It never starts a microphone session.
public struct UnwiredSpeechRecognizer: SpeechRecognizing {
    public var engineName: String { "unwired" }

    public init() {}

    public func transcribe(language: TypingLanguage) async throws -> RecognizedUtterance {
        _ = language
        throw SpeechStubError.notImplemented
    }
}

public enum SpeechEngines {
    /// Demo fixtures are the only engine linked today.
    /// A future on-device recognizer can be returned from here behind an explicit opt-in.
    /// This package does not depend on WhisperKit or any other model runtime.
    public static func make(demoMode: Bool, delayNanoseconds: UInt64 = 700_000_000) -> any SpeechRecognizing {
        if demoMode {
            return DemoSpeechRecognizer(delayNanoseconds: delayNanoseconds)
        }
        return UnwiredSpeechRecognizer()
    }
}

/// Older call site kept so `recognizeOnce()` still means "no audio engine".
/// The keyboard uses `SpeechEngines` instead, and only inserts text in demo mode.
public struct SpeechRecognizerStub: Sendable {
    public init() {}

    public func statusLine(hasFullAccess: Bool) -> String {
        let access = hasFullAccess ? "完全访问已开" : "完全访问未开"
        return "识别未接入，不会录音。可在主 App 打开演示模式。\(access)"
    }

    public func recognizeOnce() async throws -> String {
        throw SpeechStubError.notImplemented
    }
}
