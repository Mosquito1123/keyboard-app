import Foundation

public enum SpeechPermissionState: String, Sendable, Equatable {
    case authorized
    case notDetermined
    case denied
    case restricted
    /// Speech framework is not on this platform (tests, or a non-iOS build).
    case unavailable
}

public enum MicrophonePermissionState: String, Sendable, Equatable {
    case granted
    case undetermined
    case denied
    case unavailable
}

public struct OnDeviceSpeechAvailability: Sendable, Equatable {
    public var speech: SpeechPermissionState
    public var microphone: MicrophonePermissionState
    /// `nil` when the Speech framework cannot be asked (not iOS).
    public var onDeviceSupported: Bool?
    public var localeIdentifier: String

    public var canDictate: Bool {
        speech == .authorized && microphone == .granted && onDeviceSupported == true
    }

    public init(
        speech: SpeechPermissionState,
        microphone: MicrophonePermissionState,
        onDeviceSupported: Bool?,
        localeIdentifier: String
    ) {
        self.speech = speech
        self.microphone = microphone
        self.onDeviceSupported = onDeviceSupported
        self.localeIdentifier = localeIdentifier
    }
}

/// Reads or requests microphone and speech authorization.
/// The containing app is the reliable place to present the system prompts.
/// The keyboard may also call `request` after Full Access is on; if the prompt
/// cannot appear there, the state stays `.notDetermined`.
public enum OnDeviceSpeechAccess {
    public static func current(language: TypingLanguage) -> OnDeviceSpeechAvailability {
        #if os(iOS)
        return IOSSpeechAccess.snapshot(language: language)
        #else
        return unavailable(language)
        #endif
    }

    public static func request(language: TypingLanguage) async -> OnDeviceSpeechAvailability {
        #if os(iOS)
        return await IOSSpeechAccess.request(language: language)
        #else
        return unavailable(language)
        #endif
    }

    static func unavailable(_ language: TypingLanguage) -> OnDeviceSpeechAvailability {
        OnDeviceSpeechAvailability(
            speech: .unavailable,
            microphone: .unavailable,
            onDeviceSupported: nil,
            localeIdentifier: language.speechLocaleIdentifier
        )
    }
}
