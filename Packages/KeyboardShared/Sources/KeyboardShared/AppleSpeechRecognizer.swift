import Foundation

#if os(iOS)
import AVFoundation
import Speech

enum IOSSpeechAccess {
    static func snapshot(language: TypingLanguage) -> OnDeviceSpeechAvailability {
        OnDeviceSpeechAvailability(
            speech: speechState(),
            microphone: microphoneState(),
            onDeviceSupported: supportsOnDevice(language),
            localeIdentifier: language.speechLocaleIdentifier
        )
    }

    static func request(language: TypingLanguage) async -> OnDeviceSpeechAvailability {
        if speechState() == .notDetermined {
            _ = await requestSpeechAuthorization()
        }
        if microphoneState() == .undetermined {
            _ = await requestMicrophonePermission()
        }
        return snapshot(language: language)
    }

    static func ensureReady(for language: TypingLanguage) async throws {
        if speechState() == .notDetermined {
            _ = await requestSpeechAuthorization()
        }
        switch speechState() {
        case .authorized:
            break
        case .denied:
            throw SpeechFailure.speechDenied
        case .restricted:
            throw SpeechFailure.speechRestricted
        case .notDetermined:
            throw SpeechFailure.speechNotDetermined
        case .unavailable:
            throw SpeechFailure.recognizerUnavailable
        }

        if microphoneState() == .undetermined {
            _ = await requestMicrophonePermission()
        }
        switch microphoneState() {
        case .granted:
            break
        case .denied, .undetermined:
            throw SpeechFailure.microphoneDenied
        case .unavailable:
            throw SpeechFailure.recognizerUnavailable
        }

        guard supportsOnDevice(language) == true else {
            throw SpeechFailure.onDeviceUnavailable
        }
    }

    private static func speechState() -> SpeechPermissionState {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private static func microphoneState() -> MicrophonePermissionState {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .undetermined
        @unknown default:
            return .undetermined
        }
    }

    private static func supportsOnDevice(_ language: TypingLanguage) -> Bool {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.speechLocaleIdentifier)) else {
            return false
        }
        return recognizer.isAvailable && recognizer.supportsOnDeviceRecognition
    }

    private static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        }
    }

    private static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

/// On-device dictation through `SFSpeechRecognizer`.
/// `requiresOnDeviceRecognition` stays on. A failure never retries against Apple's servers.
public struct AppleOnDeviceSpeechRecognizer: SpeechRecognizing, Sendable {
    public var engineName: String { "apple-speech-on-device" }
    private let control: DictationControl

    public init(control: DictationControl = DictationControl()) {
        self.control = control
    }

    public func transcribe(language: TypingLanguage) async throws -> RecognizedUtterance {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await IOSSpeechAccess.ensureReady(for: language)
            let text = try await OnDeviceRecognitionSession(language: language, control: control).recognize()
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw SpeechFailure.noSpeech
            }
            return RecognizedUtterance(text: trimmed, engineName: engineName, usedDemoFixture: false)
        } onCancel: {
            control.cancel()
        }
    }
}

/// Listens until the caller finishes, speech goes quiet, or a short cap is reached.
@MainActor
private final class OnDeviceRecognitionSession {
    private let language: TypingLanguage
    private let control: DictationControl
    private let box = ResumeBox()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var watchdog: Task<Void, Never>?
    private var tapInstalled = false
    private var didEndAudio = false
    private var startedAt: ContinuousClock.Instant?
    private var lastPartialAt: ContinuousClock.Instant?
    private var endedAt: ContinuousClock.Instant?
    private var observedPartial = ""

    init(language: TypingLanguage, control: DictationControl) {
        self.language = language
        self.control = control
    }

    func recognize() async throws -> String {
        defer { cleanup() }
        return try await withCheckedThrowingContinuation { continuation in
            box.store(continuation)
            control.onFinish { [weak self] in
                Task { @MainActor in
                    self?.endListening()
                }
            }
            control.onCancel { [weak self] in
                Task { @MainActor in
                    self?.abort()
                }
            }
            do {
                try startEngine()
            } catch {
                box.resume(throwing: error)
            }
        }
    }

    private func startEngine() throws {
        if control.isCancelRequested {
            throw CancellationError()
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.speechLocaleIdentifier)),
              recognizer.isAvailable,
              recognizer.supportsOnDeviceRecognition
        else {
            throw SpeechFailure.onDeviceUnavailable
        }
        self.recognizer = recognizer

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechFailure.audioSessionFailed(code: (error as NSError).code)
        }

        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.taskHint = .dictation
        request.addsPunctuation = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechFailure.audioSessionFailed(code: 0)
        }

        let recognitionRequest = request
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        tapInstalled = true
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw SpeechFailure.audioSessionFailed(code: (error as NSError).code)
        }

        let clock = ContinuousClock()
        startedAt = clock.now
        lastPartialAt = clock.now
        recognitionTask = self.recognizer?.recognitionTask(with: request) { [box, control] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                box.setLatest(text)
                control.publishPartial(text)
                if result.isFinal {
                    box.resume(returning: text)
                    return
                }
            }
            if error != nil {
                if control.isCancelRequested {
                    box.resume(throwing: CancellationError())
                    return
                }
                let text = box.latestText().trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    box.resume(returning: text)
                } else if box.prefersNoSpeech {
                    box.resume(throwing: SpeechFailure.noSpeech)
                } else {
                    box.resume(throwing: SpeechFailure.interrupted)
                }
            }
        }

        watchdog = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if Task.isCancelled { return }
                self.pollWatchdog()
            }
        }

        if control.isFinishRequested {
            endListening()
        }
    }

    private func pollWatchdog() {
        let clock = ContinuousClock()
        let now = clock.now
        guard let startedAt else { return }
        let latest = box.latestText()
        if latest != observedPartial {
            observedPartial = latest
            lastPartialAt = now
        }
        let elapsed = startedAt.duration(to: now)
        let quietFor = (lastPartialAt ?? startedAt).duration(to: now)
        let heard = !latest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !didEndAudio {
            let silence = heard && quietFor > .milliseconds(1600) && elapsed > .milliseconds(800)
            let noSpeechCap = !heard && elapsed > .seconds(6)
            let hardCap = elapsed > .seconds(18)
            if noSpeechCap {
                box.markPrefersNoSpeech()
            }
            if control.isFinishRequested || silence || noSpeechCap || hardCap {
                endListening()
            }
        }
        if didEndAudio {
            if endedAt == nil {
                endedAt = now
            }
            if let endedAt, endedAt.duration(to: now) > .seconds(2) {
                let text = latest.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.isEmpty {
                    box.resume(throwing: SpeechFailure.noSpeech)
                } else {
                    box.resume(returning: text)
                }
            }
        }
    }

    private func endListening() {
        guard !didEndAudio else { return }
        didEndAudio = true
        endedAt = ContinuousClock().now
        removeTap()
        request.endAudio()
    }

    private func abort() {
        didEndAudio = true
        removeTap()
        recognitionTask?.cancel()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        box.resume(throwing: CancellationError())
    }

    private func removeTap() {
        guard tapInstalled else { return }
        tapInstalled = false
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func cleanup() {
        watchdog?.cancel()
        watchdog = nil
        removeTap()
        recognitionTask?.cancel()
        recognitionTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private final class ResumeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Error>?
    private var latest = ""
    private var resumed = false
    private var emptyFinish = false

    func store(_ continuation: CheckedContinuation<String, Error>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func setLatest(_ text: String) {
        lock.lock()
        latest = text
        lock.unlock()
    }

    func latestText() -> String {
        lock.lock()
        defer { lock.unlock() }
        return latest
    }

    func markPrefersNoSpeech() {
        lock.lock()
        emptyFinish = true
        lock.unlock()
    }

    var prefersNoSpeech: Bool {
        lock.lock()
        defer { lock.unlock() }
        return emptyFinish
    }

    func resume(returning text: String) {
        lock.lock()
        guard !resumed, let continuation else {
            lock.unlock()
            return
        }
        resumed = true
        self.continuation = nil
        lock.unlock()
        continuation.resume(returning: text)
    }

    func resume(throwing error: Error) {
        lock.lock()
        guard !resumed, let continuation else {
            lock.unlock()
            return
        }
        resumed = true
        self.continuation = nil
        lock.unlock()
        continuation.resume(throwing: error)
    }
}
#endif
