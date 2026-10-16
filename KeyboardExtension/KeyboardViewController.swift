import KeyboardShared
import UIKit

final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {
    private let keyboardView = KeyboardView()
    private var heightConstraint: NSLayoutConstraint?
    private var workTask: Task<Void, Never>?
    private var workGeneration = 0
    private var rewriteTask: Task<Void, Never>?
    private var rewriteGeneration = 0
    private var dictationControl: DictationControl?
    private var finishingDictation = false
    private var lastDictatedText: String?
    private var toneWatch: Timer?

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
        refreshToneActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshChrome()
        refreshToneActions()
        startToneWatch()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopToneWatch()
        cancelWork(announce: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if heightConstraint?.constant != preferredHeight {
            heightConstraint?.constant = preferredHeight
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshToneActions()
    }

    private var preferredHeight: CGFloat {
        if traitCollection.userInterfaceIdiom == .pad { return 420 }
        if traitCollection.verticalSizeClass == .compact { return 308 }
        return 360
    }

    private func preferencesForKeyboard() -> (prefs: KeyboardPreferences, synced: Bool, shared: Bool) {
        let shared = SharedStore.usesAppGroup
        if hasFullAccess {
            return (PreferenceStore.load(), true, shared)
        }
        return (.builtInFallback, false, shared)
    }

    private func refreshChrome() {
        let snapshot = preferencesForKeyboard()
        primaryLanguage = snapshot.prefs.language.rawValue
        keyboardView.applyChrome(
            language: snapshot.prefs.language,
            demoEnabled: snapshot.prefs.demoModeEnabled,
            synced: snapshot.synced,
            shared: snapshot.shared
        )
    }

    private func refreshToneActions() {
        let enabled = workTask == nil && rewriteTarget() != nil
        keyboardView.setToneActionsEnabled(enabled)
    }

    private func startToneWatch() {
        stopToneWatch()
        let timer = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.refreshToneActions()
        }
        RunLoop.main.add(timer, forMode: .common)
        toneWatch = timer
    }

    private func stopToneWatch() {
        toneWatch?.invalidate()
        toneWatch = nil
    }

    private func cancelWork(announce: Bool) {
        workGeneration += 1
        dictationControl?.cancel()
        dictationControl = nil
        finishingDictation = false
        workTask?.cancel()
        workTask = nil
        refreshToneActions()
        guard announce else { return }
        let snapshot = preferencesForKeyboard()
        keyboardView.showVoice(
            title: L10n.Keyboard.voiceCancelled,
            detail: "",
            phase: .success,
            demoMic: usesDemo(snapshot)
        )
    }

    private func usesDemo(_ snapshot: (prefs: KeyboardPreferences, synced: Bool, shared: Bool)) -> Bool {
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
            phase: .processing,
            demoMic: true
        )
        let engine = SpeechEngines.make(demoMode: true)
        runWork(demoMic: true, failureDetail: L10n.Keyboard.voiceFailedDetail) { @MainActor [weak self] in
            let utterance = try await engine.transcribe(language: language)
            guard let self else { return }
            KeyFeedback.tap()
            self.textDocumentProxy.insertText(utterance.text)
            self.lastDictatedText = utterance.text
            self.keyboardView.showVoice(
                title: L10n.Keyboard.voiceDoneDemoTitle,
                detail: utterance.text,
                phase: .success,
                demoMic: true
            )
            self.refreshToneActions()
        }
    }

    private func beginOnDeviceDictation(language: TypingLanguage) {
        let availability = OnDeviceSpeechAccess.current(language: language)
        if let blocked = blockedSpeechCopy(availability) {
            keyboardView.showVoice(title: blocked.title, detail: blocked.detail, phase: .error, demoMic: false)
            return
        }

        let waitingForPrompt = availability.speech == .notDetermined || availability.microphone == .undetermined
        keyboardView.showVoice(
            title: waitingForPrompt ? L10n.Keyboard.voiceRequestingTitle : L10n.Keyboard.voiceListeningTitle,
            detail: waitingForPrompt ? L10n.Keyboard.voiceRequestingDetail : L10n.Keyboard.voiceListeningDetail,
            phase: waitingForPrompt ? .processing : .listening,
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
                    phase: .listening,
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
                    self?.refreshToneActions()
                }
            }
            do {
                let utterance = try await engine.transcribe(language: language)
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                guard utterance.usedDemoFixture == false else { return }
                KeyFeedback.tap()
                self.textDocumentProxy.insertText(utterance.text)
                self.lastDictatedText = utterance.text
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceDoneTitle,
                    detail: utterance.text,
                    phase: .success,
                    demoMic: false
                )
                self.refreshToneActions()
            } catch is CancellationError {
                return
            } catch let failure as SpeechFailure {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                let copy = L10n.Keyboard.speechFailure(for: failure)
                self.keyboardView.showVoice(title: copy.title, detail: copy.detail, phase: .error, demoMic: false)
            } catch {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: L10n.Keyboard.voiceFailedDetail,
                    phase: .error,
                    demoMic: false
                )
            }
        }
        refreshToneActions()
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

    private func startRewrite(tone: RewriteTone) {
        guard workTask == nil else { return }
        guard let target = rewriteTarget() else {
            keyboardView.showToast(L10n.Keyboard.rewriteEmptyTitle, kind: .failure)
            refreshToneActions()
            return
        }
        rewriteTask?.cancel()
        rewriteGeneration += 1
        let generation = rewriteGeneration
        let language = preferencesForKeyboard().prefs.language
        let engine = RewriteEngines.make(demoMode: false)
        keyboardView.showToast(L10n.Keyboard.rewriteWorkingTitle(tone), kind: .working)
        rewriteTask = Task { @MainActor [weak self] in
            defer {
                if self?.rewriteGeneration == generation {
                    self?.rewriteTask = nil
                }
            }
            do {
                let passage = try await engine.rewrite(target.source, language: language, tone: tone)
                guard let self, !Task.isCancelled, self.rewriteGeneration == generation else { return }
                if self.commitRewrite(target, replacement: passage.text) {
                    self.keyboardView.showToast(L10n.Keyboard.rewriteDoneTitle(tone), kind: .success)
                } else {
                    self.keyboardView.showToast(L10n.Keyboard.rewriteStaleDetail, kind: .failure)
                }
            } catch is CancellationError {
                return
            } catch is RewriteFailure {
                guard let self, self.rewriteGeneration == generation else { return }
                self.keyboardView.showToast(L10n.Keyboard.rewriteEmptyTitle, kind: .failure)
            } catch {
                guard let self, !Task.isCancelled, self.rewriteGeneration == generation else { return }
                self.keyboardView.showToast(L10n.Keyboard.rewriteFailedDetail, kind: .failure)
            }
            self?.refreshToneActions()
        }
    }

    /// Selected text wins. Otherwise the last dictation is used when it is still
    /// sitting before the cursor. The last resort is a short suffix before the cursor.
    private func rewriteTarget() -> RewriteTarget? {
        if let selected = textDocumentProxy.selectedText {
            let trimmed = selected.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, trimmed.count <= 500 {
                return RewriteTarget(source: trimmed, kind: .selection)
            }
        }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if let last = lastDictatedText {
            let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, before.hasSuffix(last) {
                return RewriteTarget(source: last, kind: .beforeCursor(last))
            }
            if !trimmed.isEmpty, before.hasSuffix(trimmed) {
                return RewriteTarget(source: trimmed, kind: .beforeCursor(trimmed))
            }
        }
        let snippet = String(before.suffix(160))
        let trimmed = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return RewriteTarget(source: snippet, kind: .beforeCursor(snippet))
    }

    /// Inserts only when the captured text is still the selection or the suffix
    /// before the cursor. Typing during the pass leaves the field alone.
    private func commitRewrite(_ target: RewriteTarget, replacement: String) -> Bool {
        switch target.kind {
        case .selection:
            let selected = textDocumentProxy.selectedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard selected == target.source else { return false }
            KeyFeedback.tap()
            textDocumentProxy.insertText(replacement)
        case .beforeCursor(let snippet):
            let current = textDocumentProxy.documentContextBeforeInput ?? ""
            guard !snippet.isEmpty, current.hasSuffix(snippet) else { return false }
            for _ in snippet {
                textDocumentProxy.deleteBackward()
            }
            KeyFeedback.tap(haptic: false)
            textDocumentProxy.insertText(replacement)
        }
        lastDictatedText = replacement
        return true
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
                    self?.refreshToneActions()
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
                    phase: .error,
                    demoMic: demoMic
                )
            } catch {
                guard let self, !Task.isCancelled, self.workGeneration == generation else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: failureDetail,
                    phase: .error,
                    demoMic: demoMic
                )
            }
        }
        refreshToneActions()
    }
}

private struct RewriteTarget {
    enum Kind {
        case selection
        case beforeCursor(String)
    }

    var source: String
    var kind: Kind
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ keyboardView: KeyboardView, didPerform action: KeyboardAction) {
        switch action {
        case .insert(let text):
            textDocumentProxy.insertText(text)
            refreshToneActions()
        case .backspace:
            textDocumentProxy.deleteBackward()
            refreshToneActions()
        case .nextKeyboard:
            advanceToNextInputMode()
        case .microphone:
            if let control = dictationControl {
                finishingDictation = true
                control.requestFinish()
                keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFinishingTitle,
                    detail: L10n.Keyboard.voiceFinishingDetail,
                    phase: .processing,
                    demoMic: false
                )
            } else if workTask != nil {
                cancelWork(announce: true)
            } else {
                startDictation()
            }
        case .rewrite(let tone):
            guard workTask == nil else { return }
            startRewrite(tone: tone)
        }
    }
}
