import Foundation

public struct SetupStep: Identifiable, Sendable, Equatable {
    public let id: Int
    public let title: String
    public let titleEn: String
    public let detail: String
    public let detailEn: String

    public init(id: Int, title: String, titleEn: String, detail: String, detailEn: String) {
        self.id = id
        self.title = title
        self.titleEn = titleEn
        self.detail = detail
        self.detailEn = detailEn
    }
}

public enum L10n {
    public enum App {
        public static let eyebrow = "隐私优先 · 系统键盘骨架"
        public static let eyebrowEn = "Privacy-first system keyboard skeleton"
        public static let lead = "这一版负责把键盘装进 iOS，并留出语音与语言模型的接口。它不会录音，也不会把文字送到任何服务器。"
        public static let leadEn = "This version installs the keyboard and leaves interfaces for speech and a language model. It does not record audio or send text to a server."

        public static let enableHeading = "启用键盘"
        public static let enableHeadingEn = "Enable the keyboard"

        public static let steps: [SetupStep] = [
            SetupStep(
                id: 1,
                title: "打开系统设置",
                titleEn: "Open Settings",
                detail: "前往「设置 → 通用 → 键盘 → 键盘 → 添加新键盘」。",
                detailEn: "Go to Settings → General → Keyboard → Keyboards → Add New Keyboard."
            ),
            SetupStep(
                id: 2,
                title: "添加「键盘项目」",
                titleEn: "Add KeyboardApp",
                detail: "在第三方键盘列表里选择「键盘项目」。",
                detailEn: "Choose 键盘项目 under third-party keyboards."
            ),
            SetupStep(
                id: 3,
                title: "打开允许完全访问",
                titleEn: "Turn on Allow Full Access",
                detail: "点进刚添加的「键盘项目」，打开「允许完全访问」。系统会显示苹果的标准警告。这一版仍然不会上传按键或音频。",
                detailEn: "Tap the keyboard you just added and turn on Allow Full Access. iOS shows Apple’s standard warning. This build still does not upload keystrokes or audio."
            ),
            SetupStep(
                id: 4,
                title: "用地球键切换",
                titleEn: "Switch with the globe key",
                detail: "回到任意输入框，长按或点按地球键，选中「键盘项目」。",
                detailEn: "Focus any text field, then tap or hold the globe key and select 键盘项目."
            )
        ]

        public static let fullAccessTitle = "为什么需要完全访问"
        public static let fullAccessTitleEn = "Why Full Access is requested"
        public static let fullAccessBody = "键盘扩展的 Info.plist 已把 RequestsOpenAccess 设为 true，设置里才会出现「允许完全访问」。以后若要在设备上使用麦克风，或和主 App 共享 App Group，都需要这一项。没有打开时，占位按键仍然可以输入文字。"
        public static let fullAccessBodyEn = "The extension’s Info.plist sets RequestsOpenAccess to true, which is what makes Allow Full Access appear. A future on-device microphone, and any App Group shared with the containing app, depend on that switch. Placeholder keys still type when it is off."

        public static let micTitle = "麦克风还没接上"
        public static let micTitleEn = "The microphone is not connected"
        public static let micBody = "苹果并没有公开保证自定义键盘扩展可以录音，即便用户打开了完全访问。本骨架的麦克风按钮只更新一行状态，不创建音频会话，也不调用识别。真机上需要单独验证；若扩展不能采集音频，应改由主 App 录音，再通过 App Group 把文本交回键盘。"
        public static let micBodyEn = "Apple does not publicly guarantee that a custom keyboard extension can record, even with Full Access on. The microphone button only updates a status line. It does not create an audio session or start recognition. Verify capture on a device; if the extension cannot record, capture in the containing app and return text through the App Group."

        public static let scopeTitle = "这一版故意没做"
        public static let scopeTitleEn = "Intentionally out of scope"
        public static let scopeItems: [(String, String)] = [
            ("WhisperKit 或任何语音识别模型", "WhisperKit or any speech model"),
            ("端侧大语言模型", "An on-device large language model"),
            ("App Store 内购", "App Store in-app purchase"),
            ("需要密钥的云端识别或生成接口", "Cloud recognition or generation APIs that need a key")
        ]

        public static let idTitle = "需要你改掉的标识"
        public static let idTitleEn = "Identifiers you should replace"
        public static let idFootnote = "签名前请同时修改 Xcode 的 Bundle Identifier、两个 entitlements 里的 App Group，以及 AppIdentity.swift，让它们保持一致。"
        public static let idFootnoteEn = "Before signing, change the Xcode bundle identifiers, the App Group in both entitlements files, and AppIdentity.swift so they match."
        public static let runningAs = "当前 App 的 Bundle ID"
        public static let runningAsEn = "Bundle ID of this running app"

        public static let tryTitle = "在这里试键盘"
        public static let tryTitleEn = "Try the keyboard here"
        public static let tryBody = "启用之后点下面的输入框，再用地球键切换过来。模拟器若只显示硬件键盘，用 I/O → Keyboard → Toggle Software Keyboard。"
        public static let tryBodyEn = "After enabling it, focus the field below and switch with the globe key. On the Simulator, if only the hardware keyboard is active, use I/O → Keyboard → Toggle Software Keyboard."
        public static let tryPlaceholder = "点此输入"
        public static let versionPrefix = "骨架"
    }

    public enum Keyboard {
        public static let banner = "骨架键盘 · 识别未接入"
        public static let bannerEn = "Skeleton · recognition not wired"
        public static let micTitle = "语音"
        public static let space = "空格"
        public static let accessOn = "完全访问：开"
        public static let accessOff = "完全访问：关"
        public static let micHint = "不会开始录音"
        public static let globeHint = "切换键盘"
        public static let deleteHint = "删除"
        public static let returnHint = "换行"
    }
}
