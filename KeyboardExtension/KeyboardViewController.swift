import KeyboardShared
import UIKit

final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {
    private let keyboardView = KeyboardView()
    private var heightConstraint: NSLayoutConstraint?
    private var workTask: Task<Void, Never>?
    private var workGeneration = 0
    private var dictationControl: DictationControl?
    private var finishingDictation = false

    var enableInputClicksWhenVisible: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.canvas.uiColor

        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        view.addSubview(keyboardView)

        let height = view.heightAnchor.constraint(equalToConstant: preferredHeight)
        height.priority = UILayoutPriority(999)
        heightConstraint = height

        NSLayoutConstraint.activate([
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height
        ])
        refreshChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshChrome()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelWork(announce: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if heightConstraint?.constant != preferredHeight {
            heightConstraint?.constant = preferredHeight
        }
    }

    private var preferredHeight: CGFloat {
        traitCollection.userInterfaceIdiom == .pad ? 388 : 332
    }

    private func preferencesForKeyboard() -> (prefs: KeyboardPreferences, synced: Bool) {
        if hasFullAccess {
            return (PreferenceStore.load(), true)
        }
        return (.builtInFallback, false)
    }

    private func refreshChrome() {
        let snapshot = preferencesForKeyboard()
        primaryLanguage = snapshot.prefs.language.rawValue
        keyboardView.applyChrome(
            language: snapshot.prefs.language,
            demoEnabled: snapshot.prefs.demoModeEnabled,
            synced: snapshot.synced
        )
    }

    private func cancelWork(announce: Bool) {
        workGeneration += 1
        dictationControl?.cancel()
        dictationControl = nil
        finishingDictation = false
        workTask?.cancel()
        workTask = nil
        guard announce else { return }
        let snapshot = preferencesForKeyboard()
        keyboardView.showVoice(
            title: L10n.Keyboard.voiceIdleTitle,
            detail: L10n.Keyboard.voiceCancelled,
            busy: false,
            demoMic: usesDemo(snapshot)
        )
    }

    private func usesDemo(_ snapshot: (prefs: KeyboardPreferences, synced: Bool)) -> Bool {
        !snapshot.synced || snapshot.prefs.demoModeEnabled
    }

    private func startDictation() {
        let snapshot = preferencesForKeyboard()
        if usesDemo(snapshot) {
            beginDemoDictation(language: snapshot.prefs.language)
            return
        }
        beginOnDeviceDictation(language: snapshot.prefs.language)
    }

    private func beginDemoDictation(language: TypingLanguage) {
        keyboardView.showVoice(
            title: L10n.Keyboard.voiceWorkingTitle,
            detail: L10n.Keyboard.voiceWorkingDetail,
            busy: true,
            demoMic: true
        )
        let engine = SpeechEngines.make(demoMode: true)
        runWork(demoMic: true, failureDetail: L10n.Keyboard.voiceFailedDetail) { @MainActor [weak self] in
            let utterance = try await engine.transcribe(language: language)
            guard let self else { return }
            UIDevice.current.playInputClick()
            self.textDocumentProxy.insertText(utterance.text)
            self.keyboardView.showVoice(
                title: L10n.Keyboard.voiceDoneDemoTitle,
                detail: utterance.text,
                busy: false,
                demoMic: true
            )
        }
    }

    private func beginOnDeviceDictation(language: TypingLanguage) {
        let availability = OnDeviceSpeechAccess.current(language: language)
        if let blocked = blockedSpeechCopy(availability) {
            keyboardView.showVoice(title: blocked.title, detail: blocked.detail, busy: false, demoMic: false)
            return
        }

        let waitingForPrompt = availability.speech == .notDetermined || availability.microphone == .undetermined
        keyboardView.showVoice(
            title: waitingForPrompt ? L10n.Keyboard.voiceRequestingTitle : L10n.Keyboard.voiceListeningTitle,
            detail: waitingForPrompt ? L10n.Keyboard.voiceRequestingDetail : L10n.Keyboard.voiceListeningDetail,
            busy: true,
            demoMic: false
        )

        let control = DictationControl()
        dictationControl = control
        finishingDictation = false
        let generation = beginGeneration()
        control.onPartial { [weak self] text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            Task { @MainActor [weak self] in
                guard let self, self.workGeneration == generation, !self.finishingDictation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceListeningTitle,
                    detail: trimmed,
                    busy: true,
                    demoMic: false
                )
            }
        }

        let engine = SpeechEngines.make(demoMode: false, control: control)
        workTask = Task { @MainActor [weak self] in
            defer {
                if self?.workGeneration == generation {
                    self?.workTask = nil
                    self?.dictationControl = nil
                    self?.finishingDictation = false
                }
            }
            do {
                let utterance = try await engine.transcribe(language: language)
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                guard utterance.usedDemoFixture == false else { return }
                UIDevice.current.playInputClick()
                self.textDocumentProxy.insertText(utterance.text)
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceDoneTitle,
                    detail: utterance.text,
                    busy: false,
                    demoMic: false
                )
            } catch is CancellationError {
                return
            } catch let failure as SpeechFailure {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                let copy = L10n.Keyboard.speechFailure(for: failure)
                self.keyboardView.showVoice(title: copy.title, detail: copy.detail, busy: false, demoMic: false)
            } catch {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: L10n.Keyboard.voiceFailedDetail,
                    busy: false,
                    demoMic: false
                )
            }
        }
    }

    private func blockedSpeechCopy(_ availability: OnDeviceSpeechAvailability) -> (title: String, detail: String)? {
        switch availability.speech {
        case .denied:
            return L10n.Keyboard.speechFailure(for: .speechDenied)
        case .restricted:
            return L10n.Keyboard.speechFailure(for: .speechRestricted)
        case .unavailable:
            return L10n.Keyboard.speechFailure(for: .recognizerUnavailable)
        case .authorized, .notDetermined:
            break
        }
        if availability.microphone == .denied {
            return L10n.Keyboard.speechFailure(for: .microphoneDenied)
        }
        if availability.onDeviceSupported == false {
            return L10n.Keyboard.speechFailure(for: .onDeviceUnavailable)
        }
        return nil
    }

    private func startRewrite() {
        let snapshot = preferencesForKeyboard()
        let demo = usesDemo(snapshot)
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let snippet = String(context.suffix(120))
        let trimmed = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            keyboardView.showVoice(
                title: L10n.Keyboard.rewriteEmptyTitle,
                detail: L10n.Keyboard.rewriteEmptyDetail,
                busy: false,
                demoMic: demo
            )
            return
        }
        keyboardView.showVoice(
            title: L10n.Keyboard.rewriteWorkingTitle,
            detail: demo ? L10n.Keyboard.rewriteDemoWorkingDetail : L10n.Keyboard.rewriteWorkingDetail,
            busy: true,
            demoMic: demo
        )
        let language = snapshot.prefs.language
        let engine = RewriteEngines.make(demoMode: demo)
        runWork(demoMic: demo, failureDetail: L10n.Keyboard.rewriteFailedDetail) { @MainActor [weak self] in
            let passage = try await engine.rewrite(snippet, language: language)
            guard let self else { return }
            self.replaceBeforeCursor(snippet, with: passage.text)
            self.keyboardView.showVoice(
                title: passage.usedDemoFixture ? L10n.Keyboard.rewriteDoneDemoTitle : L10n.Keyboard.rewriteDoneTitle,
                detail: passage.text,
                busy: false,
                demoMic: demo
            )
        }
    }

    private func beginGeneration() -> Int {
        workGeneration += 1
        return workGeneration
    }

    private func runWork(
        demoMic: Bool,
        failureDetail: String,
        operation: @escaping @MainActor () async throws -> Void
    ) {
        let generation = beginGeneration()
        workTask = Task { @MainActor [weak self] in
            defer {
                if self?.workGeneration == generation {
                    self?.workTask = nil
                }
            }
            do {
                try await operation()
                guard self?.workGeneration == generation else { return }
            } catch is CancellationError {
                return
            } catch is RewriteFailure {
                guard let self, self.workGeneration == generation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.rewriteEmptyTitle,
                    detail: L10n.Keyboard.rewriteEmptyDetail,
                    busy: false,
                    demoMic: demoMic
                )
            } catch {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: failureDetail,
                    busy: false,
                    demoMic: demoMic
                )
            }
        }
    }

    /// Deletes the captured suffix only when it is still sitting before the cursor.
    private func replaceBeforeCursor(_ snippet: String, with replacement: String) {
        let current = textDocumentProxy.documentContextBeforeInput ?? ""
        if !snippet.isEmpty, current.hasSuffix(snippet) {
            for _ in snippet {
                textDocumentProxy.deleteBackward()
            }
        }
        UIDevice.current.playInputClick()
        textDocumentProxy.insertText(replacement)
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ keyboardView: KeyboardView, didPerform action: KeyboardAction) {
        switch action {
        case .insert(let text):
            UIDevice.current.playInputClick()
            textDocumentProxy.insertText(text)
        case .backspace:
            UIDevice.current.playInputClick()
            textDocumentProxy.deleteBackward()
        case .nextKeyboard:
            advanceToNextInputMode()
        case .microphone:
            if let control = dictationControl {
                finishingDictation = true
                control.requestFinish()
                keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFinishingTitle,
                    detail: L10n.Keyboard.voiceFinishingDetail,
                    busy: true,
                    demoMic: false
                )
            } else if workTask != nil {
                cancelWork(announce: true)
            } else {
                startDictation()
            }
        case .rewrite:
            guard workTask == nil else { return }
            startRewrite()
        }
    }
}
