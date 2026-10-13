import KeyboardShared
import UIKit

enum KeyboardAction: Equatable {
    case insert(String)
    case backspace
    case nextKeyboard
    case microphone
}

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ keyboardView: KeyboardView, didPerform action: KeyboardAction)
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?

    private let bannerLabel = UILabel()
    private let accessLabel = UILabel()
    private let statusLabel = UILabel()
    private let statusContainer = UIView()
    private let rootStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.canvas.uiColor
        build()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("KeyboardView is built in code.")
    }

    func updateAccess(_ hasFullAccess: Bool) {
        accessLabel.text = hasFullAccess ? L10n.Keyboard.accessOn : L10n.Keyboard.accessOff
    }

    func showStatus(_ text: String) {
        statusLabel.text = text
        statusContainer.isHidden = false
    }

    private func build() {
        bannerLabel.text = "\(L10n.Keyboard.banner)  ·  \(L10n.Keyboard.bannerEn)"
        bannerLabel.font = .systemFont(ofSize: 12, weight: .medium)
        bannerLabel.textColor = Theme.muted.uiColor
        bannerLabel.numberOfLines = 2

        accessLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        accessLabel.textColor = Theme.statusText.uiColor
        accessLabel.text = L10n.Keyboard.accessOff

        statusLabel.font = .systemFont(ofSize: 12, weight: .regular)
        statusLabel.textColor = Theme.statusText.uiColor
        statusLabel.numberOfLines = 0

        statusContainer.backgroundColor = Theme.statusFill.uiColor
        statusContainer.layer.cornerRadius = 10
        statusContainer.layer.cornerCurve = .continuous
        statusContainer.isHidden = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 8),
            statusLabel.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: -8)
        ])

        let textRow = row(of: ["你", "好", "Hi", "，", "。"].map { title in
            keyButton(title: title, fill: Theme.keyFill.uiColor, pressed: Theme.keyFillPressed.uiColor, foreground: Theme.keyLabel.uiColor) { [weak self] in
                self?.emit(.insert(title))
            }
        })

        let space = keyButton(title: L10n.Keyboard.space, fill: Theme.keyFill.uiColor, pressed: Theme.keyFillPressed.uiColor, foreground: Theme.keyLabel.uiColor) { [weak self] in
            self?.emit(.insert(" "))
        }
        let delete = symbolButton(systemName: "delete.left", hint: L10n.Keyboard.deleteHint, fill: Theme.quietKey.uiColor, pressed: Theme.card.uiColor, foreground: Theme.cream.uiColor) { [weak self] in
            self?.emit(.backspace)
        }
        delete.widthAnchor.constraint(equalToConstant: 72).isActive = true
        let editRow = row(of: [space, delete], distribution: .fill)

        let mic = keyButton(
            title: L10n.Keyboard.micTitle,
            systemName: "mic",
            fill: Theme.mic.uiColor,
            pressed: Theme.micPressed.uiColor,
            foreground: Theme.onMic.uiColor
        ) { [weak self] in
            self?.emit(.microphone)
        }
        mic.accessibilityIdentifier = "keyboard.microphone"
        mic.accessibilityHint = L10n.Keyboard.micHint

        let globe = symbolButton(systemName: "globe", hint: L10n.Keyboard.globeHint, fill: Theme.quietKey.uiColor, pressed: Theme.card.uiColor, foreground: Theme.cream.uiColor) { [weak self] in
            self?.emit(.nextKeyboard)
        }
        globe.widthAnchor.constraint(equalToConstant: 64).isActive = true

        let `return` = symbolButton(systemName: "arrow.turn.down.left", hint: L10n.Keyboard.returnHint, fill: Theme.quietKey.uiColor, pressed: Theme.card.uiColor, foreground: Theme.cream.uiColor) { [weak self] in
            self?.emit(.insert("\n"))
        }
        `return`.widthAnchor.constraint(equalToConstant: 64).isActive = true

        let controlRow = row(of: [mic, globe, `return`], distribution: .fill)

        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.isLayoutMarginsRelativeArrangement = true
        rootStack.layoutMargins = UIEdgeInsets(top: 10, left: 8, bottom: 14, right: 8)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        [bannerLabel, accessLabel, statusContainer, textRow, editRow, controlRow].forEach(rootStack.addArrangedSubview)
        addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    private func emit(_ action: KeyboardAction) {
        guard let delegate else { return }
        delegate.keyboardView(self, didPerform: action)
    }

    private func row(of views: [UIView], distribution: UIStackView.Distribution = .fillEqually) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = distribution
        return stack
    }

    private func keyButton(
        title: String,
        systemName: String? = nil,
        fill: UIColor,
        pressed: UIColor,
        foreground: UIColor,
        action: @escaping () -> Void
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = foreground
        config.background.backgroundColor = fill
        config.background.cornerRadius = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 18, weight: .medium)
            return outgoing
        }
        if let systemName {
            config.image = UIImage(systemName: systemName)
            config.imagePlacement = .leading
            config.imagePadding = 6
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
        }
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
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
            updated?.background.backgroundColor = button.isHighlighted ? pressed : fill
            button.configuration = updated
        }
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        return button
    }
}
