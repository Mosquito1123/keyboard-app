import CoreHaptics
import KeyboardShared
import UIKit

enum KeyboardAction: Equatable {
    case insert(String)
    case backspace
    case nextKeyboard
    case microphone
    case rewrite(RewriteTone)
}

enum VoicePhase: Equatable {
    case idle
    case listening
    case processing
    case error
    case success
}

enum StatusToast: Equatable {
    case working
    case success
    case failure
}

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ keyboardView: KeyboardView, didPerform action: KeyboardAction)
}

/// Clicks always. Haptics only when this device exposes the taptic engine.
enum KeyFeedback {
    private static let hapticsAvailable = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let selection = UISelectionFeedbackGenerator()

    static func prepare() {
        guard hapticsAvailable else { return }
        impact.prepare()
        selection.prepare()
    }

    static func tap(haptic: Bool = true) {
        UIDevice.current.playInputClick()
        guard haptic, hapticsAvailable else { return }
        impact.impactOccurred(intensity: 0.7)
        impact.prepare()
    }

    static func change() {
        UIDevice.current.playInputClick()
        guard hapticsAvailable else { return }
        selection.selectionChanged()
        selection.prepare()
    }
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?

    private let voiceTitle = UILabel()
    private let voiceDetail = UILabel()
    private let voiceWell = UIView()
    private let statusDot = UIView()
    private let toastWell = UIView()
    private let toastLabel = UILabel()
    private var micButton: UIButton!
    private var toneButtons: [UIButton] = []
    private var shiftButton: UIButton!
    private var planeButton: UIButton!
    private var commaButton: UIButton!
    private var periodButton: UIButton!

    private let letterPlane = UIStackView()
    private let digitPlane = UIStackView()
    private var letterKeys: [(lower: String, button: UIButton)] = []
    private var shifted = false
    private var showingDigits = false
    private var tonesEnabled = true
    private var voicePhase: VoicePhase = .idle
    private var voiceToken = 0
    private var toastToken = 0
    private var deleteRepeat: DispatchWorkItem?
    private var deleteRepeating = false
    private var language: TypingLanguage = .simplifiedChinese
    private var chromeDemo = true
    private var chromeSynced = false
    private var chromeShared = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.canvas.uiColor
        KeyFeedback.prepare()
        build()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("KeyboardView is built in code.")
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            endDeleteRepeat()
        }
    }

    func applyChrome(language: TypingLanguage, demoEnabled: Bool, synced: Bool, shared: Bool) {
        self.language = language
        chromeDemo = demoEnabled
        chromeSynced = synced
        chromeShared = shared
        setKeyTitle(commaButton, language.commaMark)
        setKeyTitle(periodButton, language.periodMark)
        guard voicePhase != .listening, voicePhase != .processing else { return }
        showIdle()
    }

    func showVoice(title: String, detail: String, phase: VoicePhase, demoMic: Bool) {
        let contentChanged = phase != voicePhase || title != voiceTitle.text || detail != voiceDetail.text
        voicePhase = phase
        voiceToken += 1
        let token = voiceToken

        voiceTitle.text = title
        voiceDetail.text = detail
        voiceDetail.accessibilityLabel = detail
        applyVoiceChrome(demoMic: demoMic)
        micButton.setNeedsUpdateConfiguration()

        if contentChanged {
            let announcement = detail.isEmpty ? title : "\(title)。\(detail)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }

        guard phase == .success else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.voiceToken == token else { return }
            self.showIdle()
        }
    }

    func setToneActionsEnabled(_ enabled: Bool) {
        guard enabled != tonesEnabled else { return }
        tonesEnabled = enabled
        for button in toneButtons {
            button.isEnabled = enabled
            button.alpha = enabled ? 1 : 0.38
            button.accessibilityHint = enabled ? nil : L10n.Keyboard.rewriteEmptyDetail
        }
    }

    func showToast(_ message: String, kind: StatusToast) {
        toastToken += 1
        let token = toastToken
        toastLabel.text = message
        switch kind {
        case .working:
            toastWell.backgroundColor = Theme.statusFill.uiColor
            toastLabel.textColor = Theme.cream.uiColor
        case .success:
            toastWell.backgroundColor = Theme.successFill.uiColor
            toastLabel.textColor = Theme.successText.uiColor
        case .failure:
            toastWell.backgroundColor = Theme.dangerFill.uiColor
            toastLabel.textColor = Theme.dangerText.uiColor
        }
        toastWell.transform = CGAffineTransform(translationX: 0, y: 6)
        UIView.animate(withDuration: 0.14, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            self.toastWell.alpha = 1
            self.toastWell.transform = .identity
        }
        UIAccessibility.post(notification: .announcement, argument: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self, self.toastToken == token else { return }
            UIView.animate(withDuration: 0.18) {
                self.toastWell.alpha = 0
            }
        }
    }

    private func showIdle() {
        showVoice(
            title: L10n.Keyboard.voiceIdleTitle,
            detail: L10n.Keyboard.idleDetail(
                language: language,
                demoEnabled: chromeDemo,
                synced: chromeSynced,
                shared: chromeShared
            ),
            phase: .idle,
            demoMic: !chromeSynced || chromeDemo
        )
    }

    private func build() {
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 8
        root.isLayoutMarginsRelativeArrangement = true
        root.layoutMargins = UIEdgeInsets(top: 6, left: 3, bottom: 6, right: 3)
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        configurePlanes()
        let voice = makeVoiceWell()
        let actions = makeActionStrip()
        let bottom = makeBottomRow()
        root.addArrangedSubview(voice)
        root.addArrangedSubview(actions)
        root.addArrangedSubview(letterPlane)
        root.addArrangedSubview(digitPlane)
        root.addArrangedSubview(bottom)

        voice.setContentHuggingPriority(.required, for: .vertical)
        actions.setContentHuggingPriority(.required, for: .vertical)
        bottom.setContentHuggingPriority(.defaultHigh, for: .vertical)
        letterPlane.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        digitPlane.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        letterPlane.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        digitPlane.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        installToast()
        setDigits(false, feedback: false)
        showIdle()
    }

    private func configurePlanes() {
        letterPlane.axis = .vertical
        letterPlane.spacing = 8
        letterPlane.distribution = .fillEqually
        letterPlane.addArrangedSubview(equalLetterRow(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], inset: 0))
        letterPlane.addArrangedSubview(equalLetterRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"], inset: 0.5))
        letterPlane.addArrangedSubview(makeShiftRow())

        digitPlane.axis = .vertical
        digitPlane.spacing = 8
        digitPlane.distribution = .fillEqually
        digitPlane.addArrangedSubview(symbolRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
        digitPlane.addArrangedSubview(symbolRow(["-", "/", ":", ";", "(", ")", "@", "#", "%", "&"]))
        digitPlane.addArrangedSubview(symbolRow(["?", "!", "'", "\"", "+", "=", "*", "·", "~", "…"]))
    }

    private func makeVoiceWell() -> UIView {
        voiceWell.backgroundColor = Theme.statusFill.uiColor
        voiceWell.layer.cornerRadius = 16
        voiceWell.layer.cornerCurve = .continuous
        voiceWell.clipsToBounds = true

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.backgroundColor = Theme.muted.uiColor
        statusDot.layer.cornerRadius = 4

        voiceTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        voiceTitle.textColor = Theme.cream.uiColor
        voiceTitle.numberOfLines = 1

        voiceDetail.font = .systemFont(ofSize: 12, weight: .regular)
        voiceDetail.textColor = Theme.statusText.uiColor
        voiceDetail.numberOfLines = 2
        voiceDetail.accessibilityIdentifier = "keyboard.voiceDetail"

        let titleRow = UIStackView(arrangedSubviews: [statusDot, voiceTitle])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 6

        let textColumn = UIStackView(arrangedSubviews: [titleRow, voiceDetail])
        textColumn.axis = .vertical
        textColumn.spacing = 2
        textColumn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        micButton = keyButton(
            title: "",
            systemName: "mic.fill",
            fill: Theme.mic.uiColor,
            pressed: Theme.micPressed.uiColor,
            foreground: Theme.onMic.uiColor,
            font: .systemFont(ofSize: 16, weight: .semibold),
            cornerRadius: 16,
            insets: NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        ) { [weak self] in
            self?.emit(.microphone)
        }
        micButton.accessibilityIdentifier = "keyboard.microphone"
        micButton.accessibilityLabel = L10n.Keyboard.micHint
        micButton.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var updated = button.configuration
            let busy = self.voicePhase == .listening || self.voicePhase == .processing
            updated?.image = UIImage(systemName: busy ? "stop.fill" : "mic.fill")
            updated?.baseForegroundColor = Theme.onMic.uiColor
            updated?.background.backgroundColor = button.isHighlighted ? Theme.micPressed.uiColor : Theme.mic.uiColor
            button.configuration = updated
            button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
        }

        let row = UIStackView(arrangedSubviews: [micButton, textColumn])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isUserInteractionEnabled = true
        voiceWell.addSubview(row)

        let tap = UITapGestureRecognizer(target: self, action: #selector(voiceWellTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        voiceWell.addGestureRecognizer(tap)

        micButton.widthAnchor.constraint(equalToConstant: 52).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        voiceWell.heightAnchor.constraint(equalToConstant: 64).isActive = true
        statusDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: voiceWell.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: voiceWell.trailingAnchor, constant: -10),
            row.centerYAnchor.constraint(equalTo: voiceWell.centerYAnchor)
        ])
        return voiceWell
    }

    @objc private func voiceWellTapped() {
        emit(.microphone)
    }

    private func applyVoiceChrome(demoMic: Bool) {
        let fill: UIColor
        let titleColor: UIColor
        let detailColor: UIColor
        let dot: UIColor
        switch voicePhase {
        case .idle:
            fill = Theme.statusFill.uiColor
            titleColor = Theme.cream.uiColor
            detailColor = Theme.statusText.uiColor
            dot = Theme.muted.uiColor
        case .listening:
            fill = Theme.listeningFill.uiColor
            titleColor = Theme.cream.uiColor
            detailColor = Theme.statusText.uiColor
            dot = Theme.mic.uiColor
        case .processing:
            fill = Theme.statusFill.uiColor
            titleColor = Theme.cream.uiColor
            detailColor = Theme.statusText.uiColor
            dot = Theme.statusText.uiColor
        case .error:
            fill = Theme.dangerFill.uiColor
            titleColor = Theme.dangerText.uiColor
            detailColor = Theme.dangerText.uiColor
            dot = Theme.dangerText.uiColor
        case .success:
            fill = Theme.successFill.uiColor
            titleColor = Theme.successText.uiColor
            detailColor = Theme.successText.uiColor
            dot = Theme.successText.uiColor
        }
        voiceWell.backgroundColor = fill
        voiceTitle.textColor = titleColor
        voiceDetail.textColor = detailColor
        statusDot.backgroundColor = dot
        setPulse(voicePhase == .listening)

        switch voicePhase {
        case .idle:
            micButton.accessibilityLabel = demoMic ? L10n.Keyboard.micDemoHint : L10n.Keyboard.micHint
        case .listening:
            micButton.accessibilityLabel = L10n.Keyboard.micStopHint
        case .processing:
            micButton.accessibilityLabel = L10n.Keyboard.micCancelHint
        case .error, .success:
            micButton.accessibilityLabel = L10n.Keyboard.micHint
        }
    }

    private func setPulse(_ on: Bool) {
        statusDot.layer.removeAnimation(forKey: "listen")
        statusDot.alpha = 1
        guard on else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.25
        animation.duration = 0.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        statusDot.layer.add(animation, forKey: "listen")
    }

    private func installToast() {
        toastWell.backgroundColor = Theme.statusFill.uiColor
        toastWell.layer.cornerRadius = 14
        toastWell.layer.cornerCurve = .continuous
        toastWell.alpha = 0
        toastWell.isUserInteractionEnabled = false
        toastWell.translatesAutoresizingMaskIntoConstraints = false
        toastWell.accessibilityIdentifier = "keyboard.toast"
        addSubview(toastWell)

        toastLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        toastLabel.textColor = Theme.cream.uiColor
        toastLabel.numberOfLines = 2
        toastLabel.textAlignment = .center
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastWell.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastWell.centerXAnchor.constraint(equalTo: centerXAnchor),
            toastWell.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            toastWell.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            toastWell.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            toastLabel.leadingAnchor.constraint(equalTo: toastWell.leadingAnchor, constant: 14),
            toastLabel.trailingAnchor.constraint(equalTo: toastWell.trailingAnchor, constant: -14),
            toastLabel.topAnchor.constraint(equalTo: toastWell.topAnchor, constant: 10),
            toastLabel.bottomAnchor.constraint(equalTo: toastWell.bottomAnchor, constant: -10)
        ])
    }

    private func makeActionStrip() -> UIStackView {
        let tones: [RewriteTone] = [.polish, .shorter, .formal]
        let buttons = tones.map { tone -> UIButton in
            let button = keyButton(
                title: tone.title.zh,
                fill: Theme.rewriteFill.uiColor,
                pressed: Theme.rewritePressed.uiColor,
                foreground: Theme.onRewrite.uiColor,
                font: .systemFont(ofSize: 15, weight: .semibold),
                cornerRadius: 12
            ) { [weak self] in
                self?.emit(.rewrite(tone))
            }
            button.accessibilityIdentifier = tone == .polish ? "keyboard.rewrite" : "keyboard.tone.\(tone.rawValue)"
            button.accessibilityLabel = "\(tone.title.zh) · \(tone.title.en)"
            return button
        }
        toneButtons = buttons
        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return row
    }

    private func equalLetterRow(_ letters: [String], inset: CGFloat) -> UIStackView {
        let keys = letters.map(makeLetterButton)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .fill
        row.distribution = .fill
        if inset > 0 {
            let lead = UIView()
            let trail = UIView()
            row.addArrangedSubview(lead)
            keys.forEach(row.addArrangedSubview)
            row.addArrangedSubview(trail)
            lead.widthAnchor.constraint(equalTo: keys[0].widthAnchor, multiplier: inset).isActive = true
            trail.widthAnchor.constraint(equalTo: lead.widthAnchor).isActive = true
        } else {
            keys.forEach(row.addArrangedSubview)
        }
        for key in keys.dropFirst() {
            key.widthAnchor.constraint(equalTo: keys[0].widthAnchor).isActive = true
        }
        let minHeight = row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        minHeight.priority = UILayoutPriority(250)
        minHeight.isActive = true
        return row
    }

    private func makeShiftRow() -> UIStackView {
        shiftButton = symbolButton(
            systemName: "shift",
            hint: L10n.Keyboard.shiftHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.quietKeyPressed.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            guard let self else { return }
            self.setShifted(!self.shifted, feedback: true)
        }
        shiftButton.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var updated = button.configuration
            let active = self.shifted
            updated?.image = UIImage(systemName: active ? "shift.fill" : "shift")
            updated?.baseForegroundColor = active ? Theme.keyLabel.uiColor : Theme.cream.uiColor
            let resting = active ? Theme.keyFill.uiColor : Theme.quietKey.uiColor
            let pressed = active ? Theme.keyFillPressed.uiColor : Theme.quietKeyPressed.uiColor
            updated?.background.backgroundColor = button.isHighlighted ? pressed : resting
            button.configuration = updated
            button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
        let letters = ["z", "x", "c", "v", "b", "n", "m"].map(makeLetterButton)
        let delete = makeDeleteButton()
        let row = UIStackView(arrangedSubviews: [shiftButton] + letters + [delete])
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fill
        shiftButton.widthAnchor.constraint(equalTo: letters[0].widthAnchor, multiplier: 1.5).isActive = true
        delete.widthAnchor.constraint(equalTo: letters[0].widthAnchor, multiplier: 1.5).isActive = true
        for letter in letters.dropFirst() {
            letter.widthAnchor.constraint(equalTo: letters[0].widthAnchor).isActive = true
        }
        let minHeight = row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        minHeight.priority = UILayoutPriority(250)
        minHeight.isActive = true
        return row
    }

    private func symbolRow(_ symbols: [String]) -> UIStackView {
        let keys = symbols.map { symbol in
            keyButton(
                title: symbol,
                fill: Theme.keyFill.uiColor,
                pressed: Theme.keyFillPressed.uiColor,
                foreground: Theme.keyLabel.uiColor,
                font: .systemFont(ofSize: 17, weight: .medium)
            ) { [weak self] in
                self?.emit(.insert(symbol))
            }
        }
        let row = UIStackView(arrangedSubviews: keys)
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fillEqually
        let minHeight = row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        minHeight.priority = UILayoutPriority(250)
        minHeight.isActive = true
        return row
    }

    private func makeBottomRow() -> UIStackView {
        planeButton = keyButton(
            title: "123",
            fill: Theme.quietKey.uiColor,
            pressed: Theme.quietKeyPressed.uiColor,
            foreground: Theme.cream.uiColor,
            font: .systemFont(ofSize: 15, weight: .semibold)
        ) { [weak self] in
            guard let self else { return }
            self.setDigits(!self.showingDigits, feedback: true)
        }
        planeButton.accessibilityLabel = L10n.Keyboard.planeDigitsHint

        let globe = symbolButton(
            systemName: "globe",
            hint: L10n.Keyboard.globeHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.quietKeyPressed.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            self?.emit(.nextKeyboard)
        }

        commaButton = keyButton(
            title: language.commaMark,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 17, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            self.emit(.insert(self.language.commaMark))
        }

        let space = keyButton(
            title: L10n.Keyboard.space,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 16, weight: .medium)
        ) { [weak self] in
            self?.emit(.insert(" "))
        }
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        space.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        space.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        periodButton = keyButton(
            title: language.periodMark,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 17, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            self.emit(.insert(self.language.periodMark))
        }

        let returnKey = symbolButton(
            systemName: "arrow.turn.down.left",
            hint: L10n.Keyboard.returnHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.quietKeyPressed.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            self?.emit(.insert("\n"))
        }

        let row = UIStackView(arrangedSubviews: [planeButton, globe, commaButton, space, periodButton, returnKey])
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fill
        let minHeight = row.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        minHeight.priority = UILayoutPriority(750)
        minHeight.isActive = true
        pinWidth(planeButton, 54)
        pinWidth(globe, 44)
        pinWidth(commaButton, 40)
        pinWidth(periodButton, 40)
        pinWidth(returnKey, 58)
        return row
    }

    private func pinWidth(_ view: UIView, _ width: CGFloat) {
        let constraint = view.widthAnchor.constraint(equalToConstant: width)
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
    }

    private func makeLetterButton(_ lower: String) -> UIButton {
        let button = keyButton(
            title: lower,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 18, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            let text = self.shifted ? lower.uppercased() : lower
            self.emit(.insert(text))
            if self.shifted {
                self.setShifted(false, feedback: false)
            }
        }
        button.accessibilityIdentifier = "key.\(lower)"
        letterKeys.append((lower, button))
        return button
    }

    private func makeDeleteButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "delete.left")
        config.baseForegroundColor = Theme.cream.uiColor
        config.background.backgroundColor = Theme.quietKey.uiColor
        config.background.cornerRadius = 10
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.accessibilityLabel = L10n.Keyboard.deleteHint
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseForegroundColor = Theme.cream.uiColor
            updated?.background.backgroundColor = button.isHighlighted ? Theme.quietKeyPressed.uiColor : Theme.quietKey.uiColor
            button.configuration = updated
            button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
        button.addAction(UIAction { [weak self] _ in
            self?.beginDeleteRepeat()
        }, for: .touchDown)
        button.addAction(UIAction { [weak self] _ in
            self?.endDeleteRepeat()
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        return button
    }

    private func setShifted(_ value: Bool, feedback: Bool) {
        let changed = value != shifted
        shifted = value
        UIView.performWithoutAnimation {
            for item in letterKeys {
                let title = value ? item.lower.uppercased() : item.lower
                self.setKeyTitle(item.button, title)
            }
            self.shiftButton.setNeedsUpdateConfiguration()
        }
        if feedback, changed {
            KeyFeedback.change()
        }
    }

    private func setDigits(_ digits: Bool, feedback: Bool) {
        let changed = digits != showingDigits
        showingDigits = digits
        UIView.performWithoutAnimation {
            self.letterPlane.isHidden = digits
            self.digitPlane.isHidden = !digits
            self.setKeyTitle(self.planeButton, digits ? "ABC" : "123")
            self.planeButton.accessibilityLabel = digits ? L10n.Keyboard.planeLettersHint : L10n.Keyboard.planeDigitsHint
            self.layoutIfNeeded()
        }
        if feedback, changed {
            KeyFeedback.change()
        }
    }

    private func beginDeleteRepeat() {
        endDeleteRepeat()
        deleteRepeating = true
        emit(.backspace)
        scheduleDelete(after: 0.38)
    }

    private func scheduleDelete(after delay: TimeInterval) {
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.deleteRepeating else { return }
            self.emit(.backspace, feedback: false)
            self.scheduleDelete(after: max(0.045, delay * 0.78))
        }
        deleteRepeat = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func endDeleteRepeat() {
        deleteRepeating = false
        deleteRepeat?.cancel()
        deleteRepeat = nil
    }

    private func setKeyTitle(_ button: UIButton, _ title: String) {
        var config = button.configuration
        config?.title = title
        button.configuration = config
        button.accessibilityLabel = title
    }

    private func emit(_ action: KeyboardAction, feedback: Bool = true) {
        if feedback {
            KeyFeedback.tap()
        } else {
            KeyFeedback.tap(haptic: false)
        }
        delegate?.keyboardView(self, didPerform: action)
    }

    private func keyButton(
        title: String,
        systemName: String? = nil,
        fill: UIColor,
        pressed: UIColor,
        foreground: UIColor,
        font: UIFont,
        cornerRadius: CGFloat = 10,
        insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2),
        action: @escaping () -> Void
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = foreground
        config.background.backgroundColor = fill
        config.background.cornerRadius = cornerRadius
        config.contentInsets = insets
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
        if let systemName {
            config.image = UIImage(systemName: systemName)
            config.imagePlacement = .leading
            config.imagePadding = title.isEmpty ? 0 : 4
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseForegroundColor = foreground
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
            button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
        return button
    }

    private func symbolButton(
        systemName: String,
        hint: String,
        fill: UIColor,
        pressed: UIColor,
        foreground: UIColor,
        action: @escaping () -> Void
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: systemName)
        config.baseForegroundColor = foreground
        config.background.backgroundColor = fill
        config.background.cornerRadius = 10
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.accessibilityLabel = hint
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseForegroundColor = foreground
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
            button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
        return button
    }
}

extension KeyboardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }
}
