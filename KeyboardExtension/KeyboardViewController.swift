import KeyboardShared
import UIKit

final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {
    private let keyboardView = KeyboardView()
    private var heightConstraint: NSLayoutConstraint?

    var enableInputClicksWhenVisible: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryLanguage = "zh-Hans"
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.updateAccess(hasFullAccess)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if heightConstraint?.constant != preferredHeight {
            heightConstraint?.constant = preferredHeight
        }
    }

    private var preferredHeight: CGFloat {
        traitCollection.userInterfaceIdiom == .pad ? 340 : 292
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
            // Status only. Do not create AVAudioSession and do not call recognizeOnce().
            let line = SpeechRecognizerStub().statusLine(hasFullAccess: hasFullAccess)
            keyboardView.showStatus(line)
        }
    }
}
