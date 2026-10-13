import KeyboardShared
import UIKit

final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {
    private let keyboardView = KeyboardView()
    private let speechStub = SpeechRecognizerStub()
    private var heightConstraint: NSLayoutConstraint?
    private var workTask: Task<Void, Never>?
    private var workGeneration = 0

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
        traitCollection.userInterfaceIdiom == .pad ? 372 : 316
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
        workTask?.cancel()
        workTask = nil
        guard announce else { return }
        let snapshot = preferencesForKeyboard()
        keyboardView.showVoice(
            title: L10n.Keyboard.voiceIdleTitle,
            detail: L10n.Keyboard.voiceCancelled + " " + L10n.Keyboard.idleDetail(
                language: snapshot.prefs.language,
                demoEnabled: snapshot.prefs.demoModeEnabled,
                synced: snapshot.synced
            ),
            busy: false
        )
    }

    private func startDictation() {
        let snapshot = preferencesForKeyboard()
        guard snapshot.prefs.demoModeEnabled else {
            keyboardView.showVoice(
                title: L10n.Keyboard.voiceUnwiredTitle,
                detail: speechStub.statusLine(hasFullAccess: hasFullAccess),
                busy: false
            )
            return
        }
        keyboardView.showVoice(
            title: L10n.Keyboard.voiceWorkingTitle,
            detail: L10n.Keyboard.voiceWorkingDetail,
            busy: true
        )
        let language = snapshot.prefs.language
        let engine = SpeechEngines.make(demoMode: true)
        workGeneration += 1
        let generation = workGeneration
        workTask = Task { @MainActor [weak self] in
            defer {
                if self?.workGeneration == generation {
                    self?.workTask = nil
                }
            }
            do {
                let utterance = try await engine.transcribe(language: language)
                guard let self, !Task.isCancelled else { return }
                UIDevice.current.playInputClick()
                self.textDocumentProxy.insertText(utterance.text)
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceDoneTitle,
                    detail: utterance.text,
                    busy: false
                )
            } catch is CancellationError {
                return
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: L10n.Keyboard.voiceFailedDetail,
                    busy: false
                )
            }
        }
    }

    private func startRewrite() {
        let snapshot = preferencesForKeyboard()
        guard snapshot.prefs.demoModeEnabled else {
            keyboardView.showVoice(
                title: L10n.Keyboard.rewriteTitle,
                detail: L10n.Keyboard.rewriteUnwiredDetail,
                busy: false
            )
            return
        }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let snippet = String(context.suffix(120))
        keyboardView.showVoice(
            title: L10n.Keyboard.rewriteWorkingTitle,
            detail: L10n.Keyboard.rewriteWorkingDetail,
            busy: true
        )
        let language = snapshot.prefs.language
        let engine = RewriteEngines.make(demoMode: true)
        workGeneration += 1
        let generation = workGeneration
        workTask = Task { @MainActor [weak self] in
            defer {
                if self?.workGeneration == generation {
                    self?.workTask = nil
                }
            }
            do {
                let passage = try await engine.rewrite(snippet, language: language)
                guard let self, !Task.isCancelled else { return }
                self.replaceBeforeCursor(snippet, with: passage.text)
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.rewriteDoneTitle,
                    detail: passage.text,
                    busy: false
                )
            } catch is CancellationError {
                return
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.keyboardView.showVoice(
                    title: L10n.Keyboard.voiceFailedTitle,
                    detail: L10n.Keyboard.voiceFailedDetail,
                    busy: false
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
            if workTask != nil {
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
