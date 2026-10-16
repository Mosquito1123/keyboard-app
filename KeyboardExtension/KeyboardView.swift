import KeyboardShared
import UIKit

enum KeyboardAction: Equatable {
    case insert(String)
    case backspace
    case nextKeyboard
    case microphone
    case rewrite(RewriteTone)
}

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ keyboardView: KeyboardView, didPerform action: KeyboardAction)
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?

    private let voiceTitle = UILabel()
    private let voiceDetail = UILabel()
    private let voiceWell = UIView()
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
    private var busy = false
    private var deleteTimer: Timer?
    private var language: TypingLanguage = .simplifiedChinese

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.canvas.uiColor
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
        setKeyTitle(commaButton, language.commaMark)
        setKeyTitle(periodButton, language.periodMark)
        guard !busy else { return }
        showVoice(
            title: L10n.Keyboard.voiceIdleTitle,
            detail: L10n.Keyboard.idleDetail(language: language, demoEnabled: demoEnabled, synced: synced, shared: shared),
            busy: false,
            demoMic: !synced || demoEnabled
        )
    }

    func showVoice(title: String, detail: String, busy: Bool, demoMic: Bool) {
        self.busy = busy
        voiceTitle.text = title
        voiceDetail.text = detail
        voiceDetail.accessibilityLabel = detail
        var config = micButton.configuration
        config?.image = UIImage(systemName: busy ? "stop.fill" : "mic.fill")
        micButton.configuration = config
        if busy {
            micButton.accessibilityLabel = title
        } else {
            micButton.accessibilityLabel = demoMic ? L10n.Keyboard.micDemoHint : L10n.Keyboard.micHint
        }
        for button in toneButtons {
            button.isEnabled = !busy
            button.alpha = busy ? 0.4 : 1
        }
    }

    private func build() {
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 6
        root.isLayoutMarginsRelativeArrangement = true
        root.layoutMargins = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        configurePlanes()
        root.addArrangedSubview(makeVoiceWell())
        root.addArrangedSubview(makeActionStrip())
        root.addArrangedSubview(letterPlane)
        root.addArrangedSubview(digitPlane)
        root.addArrangedSubview(makeBottomRow())

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setDigits(false)
        showVoice(
            title: L10n.Keyboard.voiceIdleTitle,
            detail: L10n.Keyboard.idleDetail(language: language, demoEnabled: true, synced: false, shared: false),
            busy: false,
            demoMic: true
        )
    }

    private func configurePlanes() {
        letterPlane.axis = .vertical
        letterPlane.spacing = 6
        letterPlane.addArrangedSubview(equalLetterRow(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], inset: 0))
        letterPlane.addArrangedSubview(equalLetterRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"], inset: 0.5))
        letterPlane.addArrangedSubview(makeShiftRow())

        digitPlane.axis = .vertical
        digitPlane.spacing = 6
        digitPlane.addArrangedSubview(symbolRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
        digitPlane.addArrangedSubview(symbolRow(["-", "/", ":", ";", "(", ")", "@", "#", "%", "&"]))
        digitPlane.addArrangedSubview(symbolRow(["?", "!", "'", "\"", "+", "=", "*", "·", "~", "…"]))
    }

    private func makeVoiceWell() -> UIView {
        voiceWell.backgroundColor = Theme.statusFill.uiColor
        voiceWell.layer.cornerRadius = 16
        voiceWell.layer.cornerCurve = .continuous

        voiceTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        voiceTitle.textColor = Theme.cream.uiColor
        voiceTitle.numberOfLines = 1

        voiceDetail.font = .systemFont(ofSize: 11, weight: .regular)
        voiceDetail.textColor = Theme.statusText.uiColor
        voiceDetail.numberOfLines = 3
        voiceDetail.accessibilityIdentifier = "keyboard.voiceDetail"

        let textColumn = UIStackView(arrangedSubviews: [voiceTitle, voiceDetail])
        textColumn.axis = .vertical
        textColumn.spacing = 2
        textColumn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        micButton = keyButton(
            title: "",
            systemName: "mic.fill",
            fill: Theme.mic.uiColor,
            pressed: Theme.micPressed.uiColor,
            foreground: Theme.onMic.uiColor,
            font: .systemFont(ofSize: 15, weight: .semibold),
            cornerRadius: 14,
            insets: NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        ) { [weak self] in
            self?.emit(.microphone)
        }
        micButton.accessibilityIdentifier = "keyboard.microphone"
        micButton.accessibilityLabel = L10n.Keyboard.micHint

        let row = UIStackView(arrangedSubviews: [micButton, textColumn])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        voiceWell.addSubview(row)

        micButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        voiceWell.heightAnchor.constraint(equalToConstant: 72).isActive = true

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: voiceWell.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: voiceWell.trailingAnchor, constant: -8),
            row.centerYAnchor.constraint(equalTo: voiceWell.centerYAnchor)
        ])
        return voiceWell
    }

    private func makeActionStrip() -> UIStackView {
        let tones: [RewriteTone] = [.polish, .shorter, .formal]
        let buttons = tones.map { tone -> UIButton in
            let button = keyButton(
                title: tone.title.zh,
                fill: Theme.rewriteFill.uiColor,
                pressed: Theme.rewritePressed.uiColor,
                foreground: Theme.onRewrite.uiColor,
                font: .systemFont(ofSize: 14, weight: .semibold),
                cornerRadius: 10
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
        row.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return row
    }

    private func equalLetterRow(_ letters: [String], inset: CGFloat) -> UIStackView {
        let keys = letters.map(makeLetterButton)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
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
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        return row
    }

    private func makeShiftRow() -> UIStackView {
        shiftButton = symbolButton(
            systemName: "shift",
            hint: L10n.Keyboard.shiftHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.card.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            guard let self else { return }
            self.setShifted(!self.shifted)
        }
        shiftButton.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var updated = button.configuration
            let active = self.shifted
            updated?.baseForegroundColor = active ? Theme.keyLabel.uiColor : Theme.cream.uiColor
            let resting = active ? Theme.keyFill.uiColor : Theme.quietKey.uiColor
            let pressed = active ? Theme.keyFillPressed.uiColor : Theme.card.uiColor
            updated?.background.backgroundColor = button.isHighlighted ? pressed : resting
            button.configuration = updated
        }
        let letters = ["z", "x", "c", "v", "b", "n", "m"].map(makeLetterButton)
        let delete = makeDeleteButton()
        let row = UIStackView(arrangedSubviews: [shiftButton] + letters + [delete])
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fill
        shiftButton.widthAnchor.constraint(equalTo: letters[0].widthAnchor, multiplier: 1.4).isActive = true
        delete.widthAnchor.constraint(equalTo: letters[0].widthAnchor, multiplier: 1.4).isActive = true
        for letter in letters.dropFirst() {
            letter.widthAnchor.constraint(equalTo: letters[0].widthAnchor).isActive = true
        }
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        return row
    }

    private func symbolRow(_ symbols: [String]) -> UIStackView {
        let keys = symbols.map { symbol in
            keyButton(
                title: symbol,
                fill: Theme.keyFill.uiColor,
                pressed: Theme.keyFillPressed.uiColor,
                foreground: Theme.keyLabel.uiColor,
                font: .systemFont(ofSize: 16, weight: .medium)
            ) { [weak self] in
                self?.emit(.insert(symbol))
            }
        }
        let row = UIStackView(arrangedSubviews: keys)
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        return row
    }

    private func makeBottomRow() -> UIStackView {
        planeButton = keyButton(
            title: "123",
            fill: Theme.quietKey.uiColor,
            pressed: Theme.card.uiColor,
            foreground: Theme.cream.uiColor,
            font: .systemFont(ofSize: 14, weight: .semibold)
        ) { [weak self] in
            guard let self else { return }
            self.setDigits(!self.showingDigits)
        }
        planeButton.accessibilityLabel = L10n.Keyboard.planeDigitsHint

        let globe = symbolButton(
            systemName: "globe",
            hint: L10n.Keyboard.globeHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.card.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            self?.emit(.nextKeyboard)
        }

        commaButton = keyButton(
            title: language.commaMark,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 16, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            self.emit(.insert(self.language.commaMark))
        }

        let space = keyButton(
            title: L10n.Keyboard.space,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 15, weight: .medium)
        ) { [weak self] in
            self?.emit(.insert(" "))
        }
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        space.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        periodButton = keyButton(
            title: language.periodMark,
            fill: Theme.keyFill.uiColor,
            pressed: Theme.keyFillPressed.uiColor,
            foreground: Theme.keyLabel.uiColor,
            font: .systemFont(ofSize: 16, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            self.emit(.insert(self.language.periodMark))
        }

        let returnKey = symbolButton(
            systemName: "arrow.turn.down.left",
            hint: L10n.Keyboard.returnHint,
            fill: Theme.quietKey.uiColor,
            pressed: Theme.card.uiColor,
            foreground: Theme.cream.uiColor
        ) { [weak self] in
            self?.emit(.insert("\n"))
        }

        let row = UIStackView(arrangedSubviews: [planeButton, globe, commaButton, space, periodButton, returnKey])
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fill
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        pinWidth(planeButton, 46)
        pinWidth(globe, 40)
        pinWidth(commaButton, 36)
        pinWidth(periodButton, 36)
        pinWidth(returnKey, 52)
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
            font: .systemFont(ofSize: 17, weight: .medium)
        ) { [weak self] in
            guard let self else { return }
            let text = self.shifted ? lower.uppercased() : lower
            self.emit(.insert(text))
            if self.shifted {
                self.setShifted(false)
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
        config.background.cornerRadius = 8
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let button = UIButton(configuration: config)
        button.accessibilityLabel = L10n.Keyboard.deleteHint
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = button.isHighlighted ? Theme.card.uiColor : Theme.quietKey.uiColor
            button.configuration = updated
        }
        button.addAction(UIAction { [weak self] _ in
            self?.beginDeleteRepeat()
        }, for: .touchDown)
        button.addAction(UIAction { [weak self] _ in
            self?.endDeleteRepeat()
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        return button
    }

    private func setShifted(_ value: Bool) {
        shifted = value
        for item in letterKeys {
            let title = value ? item.lower.uppercased() : item.lower
            setKeyTitle(item.button, title)
        }
        shiftButton.setNeedsUpdateConfiguration()
    }

    private func setDigits(_ digits: Bool) {
        showingDigits = digits
        letterPlane.isHidden = digits
        digitPlane.isHidden = !digits
        setKeyTitle(planeButton, digits ? "ABC" : "123")
        planeButton.accessibilityLabel = digits ? L10n.Keyboard.planeLettersHint : L10n.Keyboard.planeDigitsHint
    }

    private func beginDeleteRepeat() {
        endDeleteRepeat()
        emit(.backspace)
        let timer = Timer(timeInterval: 0.09, repeats: true) { [weak self] _ in
            self?.emit(.backspace)
        }
        RunLoop.main.add(timer, forMode: .common)
        deleteTimer = timer
    }

    private func endDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    private func setKeyTitle(_ button: UIButton, _ title: String) {
        var config = button.configuration
        config?.title = title
        button.configuration = config
        button.accessibilityLabel = title
    }

    private func emit(_ action: KeyboardAction) {
        delegate?.keyboardView(self, didPerform: action)
    }

    private func keyButton(
        title: String,
        systemName: String? = nil,
        fill: UIColor,
        pressed: UIColor,
        foreground: UIColor,
        font: UIFont,
        cornerRadius: CGFloat = 8,
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
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
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
        config.background.cornerRadius = 8
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.accessibilityLabel = hint
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
        }
        return button
    }
}
