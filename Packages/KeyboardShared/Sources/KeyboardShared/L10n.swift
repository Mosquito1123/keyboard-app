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
        public static let eyebrow = "离线优先 · 可在其他 App 里使用"
        public static let eyebrowEn = "Offline-first, available in other apps"
        public static let lead = "主 App 负责说明怎样启用键盘，以及完全访问打开后到底共享什么。键盘扩展可以在任意输入框里打字母，并用一条语音条插入本地示例。"
        public static let leadEn = "The app explains how to enable the keyboard and what Full Access actually shares. The extension types letters in any text field and can insert a local sample from its voice strip."

        public static let enableHeading = "三步启用"
        public static let enableHeadingEn = "Enable it in three steps"

        public static let steps: [SetupStep] = [
            SetupStep(
                id: 1,
                title: "把它加进系统键盘",
                titleEn: "Add it to the system keyboard list",
                detail: "打开「设置 → 通用 → 键盘 → 键盘 → 添加新键盘」，在第三方键盘里选择「键盘项目」。",
                detailEn: "Open Settings → General → Keyboard → Keyboards → Add New Keyboard, then choose 键盘项目 under third-party keyboards."
            ),
            SetupStep(
                id: 2,
                title: "阅读并打开完全访问",
                titleEn: "Read the note, then allow Full Access",
                detail: "再点一次「键盘项目」，打开「允许完全访问」。系统会显示苹果的标准警告。请先看下面「会用到 / 不会做」再决定。",
                detailEn: "Tap 键盘项目 again and turn on Allow Full Access. iOS shows Apple’s standard warning. Read the will / will-not list below before you decide."
            ),
            SetupStep(
                id: 3,
                title: "在输入框里切换过来",
                titleEn: "Switch to it from a text field",
                detail: "点进任意 App 的输入框，点地球键，选「键盘项目」。下面这个输入框就可以试。",
                detailEn: "Focus a text field in any app, tap the globe key, and select 键盘项目. The field below works for a first try."
            )
        ]

        public static let fullAccessTitle = "完全访问打开之后"
        public static let fullAccessTitleEn = "After Full Access is on"
        public static let fullAccessIntro = "扩展的 Info.plist 把 RequestsOpenAccess 设为 true，设置里才会出现这个开关。没有打开时，字母键仍然可以打字。"
        public static let fullAccessIntroEn = "The extension Info.plist sets RequestsOpenAccess to true, which is why the switch appears. Letter keys still type when it is off."
        public static let willHeading = "会用到"
        public static let willHeadingEn = "Used for"
        public static let wontHeading = "这一版不会"
        public static let wontHeadingEn = "This build does not"
        public static let fullAccessWill: [(String, String)] = [
            ("让键盘读到你在本 App 里选的语言和演示开关", "Let the keyboard read the language and demo switch chosen in this app"),
            ("为以后的设备端能力预留同一条共享通道", "Reserve that same shared channel for a later on-device feature")
        ]
        public static let fullAccessWont: [(String, String)] = [
            ("不打开麦克风，也不录音", "Does not open the microphone or record audio"),
            ("不上传按键、文本或音频", "Does not upload keystrokes, text, or audio"),
            ("不连接服务器，也不做统计", "Does not contact a server or collect analytics")
        ]

        public static let settingsButton = "设置"
        public static let openSettingsTitle = "语言、演示和隐私"
        public static let openSettingsTitleEn = "Language, demo, and privacy"
        public static let openSettingsBody = "演示开关默认打开。关闭后，键盘上的麦克风和润色只显示状态，不会改输入框。"
        public static let openSettingsBodyEn = "Demo mode is on by default. Turn it off and the mic and rewrite controls only show a status line."

        public static let tryTitle = "在这里试"
        public static let tryTitleEn = "Try it here"
        public static let tryBody = "启用之后点输入框，用地球键切到「键盘项目」。也可以直接在下面插入同一套示例，确认主 App 和键盘走的是同一条接口。"
        public static let tryBodyEn = "After enabling it, focus the field and switch with the globe key. You can also insert the same sample here, to confirm the app and the keyboard share one interface."
        public static let tryPlaceholder = "点此输入"
        public static let insertSample = "插入语音示例"
        public static let insertSampleEn = "Insert voice sample"
        public static let rewriteSample = "润色这段文字"
        public static let rewriteSampleEn = "Rewrite this text"
        public static let sampling = "正在等待本地示例…"
        public static let samplingEn = "Waiting for the local sample…"
        public static let demoOffNote = "演示模式已关闭。到设置里打开后，这里和键盘都会插入示例。"
        public static let demoOffNoteEn = "Demo mode is off. Turn it on in Settings and both this screen and the keyboard will insert samples."
        public static let demoFailedNote = "示例没有返回。"
        public static let demoFailedNoteEn = "The sample did not return."

        public static let systemSettings = "打开本 App 的系统设置"
        public static let systemSettingsEn = "Open this app’s Settings page"
        public static let systemSettingsNote = "这只会打开本 App 自己的系统设置页，不会跳到键盘列表。添加键盘请用上面的三步。"
        public static let systemSettingsNoteEn = "This opens this app’s own Settings page. It does not jump to the keyboard list. Use the three steps above to add the keyboard."

        public static let micTitle = "语音条还不会录音"
        public static let micTitleEn = "The voice strip still does not record"
        public static let micBody = "演示模式会在短暂停顿后插入一段写在 App 里的句子。它不创建音频会话。苹果也没有公开保证键盘扩展可以录音；真机确认之前，不要在扩展里打开麦克风。如果以后扩展不能采集音频，应改由主 App 录音，再通过 App Group 把文本交回键盘。"
        public static let micBodyEn = "Demo mode waits briefly, then inserts a sentence that ships with the app. It does not create an audio session. Apple does not publicly guarantee that a keyboard extension can record; do not open the microphone there until you have checked on a device. If the extension cannot capture audio, record in the containing app and return text through the App Group."

        public static let scopeTitle = "模型运行时还没接上"
        public static let scopeTitleEn = "Model runtimes are not linked"
        public static let scopeItems: [(String, String)] = [
            ("语音识别：只有演示样本，没有识别引擎", "Speech: demo sentences only, no recognition engine"),
            ("文本润色：只有本地整理，没有语言模型", "Rewrite: a local tidy-up only, no language model"),
            ("没有内购，也没有需要密钥的云端接口", "No in-app purchase and no cloud API that needs a key")
        ]

        public static let idTitle = "需要你改掉的标识"
        public static let idTitleEn = "Identifiers you should replace"
        public static let idFootnote = "签名前请同时修改 Xcode 的 Bundle Identifier、两个 entitlements 里的 App Group，以及 AppIdentity.swift，让它们保持一致。"
        public static let idFootnoteEn = "Before signing, change the Xcode bundle identifiers, the App Group in both entitlements files, and AppIdentity.swift so they match."
        public static let runningAs = "当前 App 的 Bundle ID"
        public static let runningAsEn = "Bundle ID of this running app"

        public static let versionPrefix = "预览"
    }

    public enum Settings {
        public static let title = "设置"
        public static let intro = "这些选项保存在 App Group 里。键盘只有在完全访问打开后才能读到它们。"
        public static let introEn = "These options live in the App Group. The keyboard can read them only after Full Access is on."

        public static let languageHeading = "语言偏好"
        public static let languageHeadingEn = "Language preference"
        public static let languageFootnote = "只影响演示例句，以及键盘上的逗号和句号。没有识别引擎会跟着切换。"
        public static let languageFootnoteEn = "This only changes the demo sentence and the comma and period on the keyboard. No recognition engine switches with it."

        public static let demoHeading = "演示模式"
        public static let demoHeadingEn = "Demo mode"
        public static let demoToggle = "用本地示例代替识别和润色"
        public static let demoToggleEn = "Use local samples instead of recognition and rewrite"
        public static let demoOnDetail = "打开时，麦克风和润色会先停一下，再插入写在 App 里的文字。不会申请麦克风，也不会联网。"
        public static let demoOnDetailEn = "When this is on, the mic and rewrite controls pause, then insert text that ships with the app. They do not request the microphone or use the network."
        public static let demoOffDetail = "关闭时，这两个控制只显示「尚未接入」，不会改动输入框。直接调用 recognizeOnce() 或 complete(prompt:) 也仍然会失败。"
        public static let demoOffDetailEn = "When this is off, those controls only show that they are unwired, and they leave the field unchanged. recognizeOnce() and complete(prompt:) still fail."
        public static let syncNote = "没打开完全访问时，键盘忽略这里的选择，改用内置值：简体中文，演示开。"
        public static let syncNoteEn = "Without Full Access the keyboard ignores this screen and uses its built-in values: Simplified Chinese, demo on."

        public static let privacyHeading = "隐私说明"
        public static let privacyHeadingEn = "Privacy notes"
        public static let privacyItems: [(String, String)] = [
            ("目标是离线：这一版没有服务器，也没有账号。", "The goal is offline use: this build has no server and no account."),
            ("演示句子是编译进 App 的文本，不是录音结果。", "Demo sentences are text compiled into the app, not a recording."),
            ("不包含统计、追踪或广告。", "There is no analytics, tracking, or advertising."),
            ("完全访问只用于共享上面的设置，不用于上传内容。", "Full Access is only for sharing the settings above, not for uploading content.")
        ]

        public static let stubHeading = "仍是占位"
        public static let stubHeadingEn = "Still stubbed"
        public static let stubItems: [(String, String)] = [
            ("SpeechRecognizing 目前只有演示实现和未接入实现。", "SpeechRecognizing currently has a demo implementation and an unwired one."),
            ("TextRewriting 只会做本地标注和空白整理，润色范围是光标前大约 120 个字。", "TextRewriting only labels and tidies text locally, using about 120 characters before the cursor."),
            ("没有模型下载，也没有几十种语言的识别包。", "There is no model download and no recognition pack for dozens of languages."),
            ("字母键是占位布局，不是中文输入法。", "The letter keys are a placeholder layout, not a Chinese input method.")
        ]

        public static func languageName(_ language: TypingLanguage) -> (String, String) {
            switch language {
            case .simplifiedChinese:
                return ("简体中文", "Simplified Chinese")
            case .english:
                return ("英语", "English")
            case .japanese:
                return ("日语", "Japanese")
            }
        }
    }

    public enum Keyboard {
        public static let voiceIdleTitle = "语音条"
        public static let voiceWorkingTitle = "正在准备示例"
        public static let voiceWorkingDetail = "稍等，将插入本地示例。不会录音。再点一次可取消。"
        public static let voiceDoneTitle = "已插入示例"
        public static let voiceCancelled = "已取消，没有插入文字。"
        public static let voiceUnwiredTitle = "识别未接入"
        public static let voiceFailedTitle = "没有插入"
        public static let voiceFailedDetail = "演示中断了。可以再点一次。"
        public static let rewriteTitle = "润色"
        public static let rewriteWorkingTitle = "正在整理"
        public static let rewriteWorkingDetail = "稍等，将处理光标前的一小段本地文本。"
        public static let rewriteDoneTitle = "已放入示例"
        public static let rewriteUnwiredDetail = "润色未接入。请在主 App 打开演示模式。"
        public static let space = "空格"
        public static let micHint = "语音示例"
        public static let rewriteHint = "示例润色"
        public static let globeHint = "切换键盘"
        public static let deleteHint = "删除"
        public static let returnHint = "换行"
        public static let shiftHint = "大小写"
        public static let planeDigitsHint = "数字"
        public static let planeLettersHint = "字母"

        public static func idleDetail(language: TypingLanguage, demoEnabled: Bool, synced: Bool) -> String {
            if !synced {
                return "完全访问未开，正在用内置演示。打开后才同步主 App。"
            }
            let name: String
            switch language {
            case .simplifiedChinese:
                name = "中文"
            case .english:
                name = "EN"
            case .japanese:
                name = "日语"
            }
            if demoEnabled {
                return "\(name) · 演示开。点麦克风插入示例，不会录音。"
            }
            return "\(name) · 演示关。麦克风只显示状态。"
        }
    }
}
