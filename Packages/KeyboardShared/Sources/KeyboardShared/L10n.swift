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
        public static let lead = "主 App 说明怎样启用键盘，以及完全访问打开后会用到什么。键盘可以在任意输入框里打字母。演示模式关闭时，麦克风走苹果的设备端语音识别；打开时只插入本地示例。"
        public static let leadEn = "The app explains how to enable the keyboard and what Full Access is used for. The keyboard types letters in any text field. With demo mode off, the mic uses Apple’s on-device speech recognition. With demo mode on, it inserts a local sample."

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
            ("在演示关闭时，为设备端听写打开麦克风。音频只在本机处理", "When demo mode is off, open the microphone for on-device dictation. Audio stays on this device")
        ]
        public static let fullAccessWont: [(String, String)] = [
            ("不上传按键、文本或音频", "Does not upload keystrokes, text, or audio"),
            ("不把语音送到识别服务器。设备端不可用时直接停止", "Does not send speech to a recognition server. If on-device recognition is unavailable, it stops"),
            ("不做追踪、广告或内购，也不保存录音", "Does not track, advertise, sell anything, or keep a recording")
        ]

        public static let settingsButton = "设置"
        public static let openSettingsTitle = "语言、演示和隐私"
        public static let openSettingsTitleEn = "Language, demo, and privacy"
        public static let openSettingsBody = "演示模式默认关闭。请先在设置里允许麦克风和语音识别，再使用本机听写。打开演示后，麦克风只插入本地示例。"
        public static let openSettingsBodyEn = "Demo mode is off by default. Allow the microphone and speech recognition in Settings before you dictate. Turn demo on and the mic only inserts a local sample."

        public static let tryTitle = "在这里试"
        public static let tryTitleEn = "Try it here"
        public static let tryBody = "启用之后点输入框，用地球键切到「键盘项目」。下面可以听写。语气整理请打开 AI 试验台，润色、更短、正式和口语都在本机完成。"
        public static let tryBodyEn = "After enabling it, focus a field and switch with the globe key. You can dictate below. Open the AI playground for polish, shorter, formal, and casual. Those passes stay on this device."
        public static let tryPlaceholder = "点此输入"
        public static let insertSample = "插入语音示例"
        public static let insertSampleEn = "Insert voice sample"
        public static let dictateNow = "本机听写"
        public static let dictateNowEn = "Dictate on device"
        public static let rewriteSample = "润色这段文字"
        public static let rewriteSampleEn = "Rewrite this text"
        public static let sampling = "正在等待本地示例…"
        public static let samplingEn = "Waiting for the local sample…"
        public static let listening = "正在听写…请说话。识别只在这台设备上进行。"
        public static let listeningEn = "Listening… speak now. Recognition stays on this device."
        public static let emptyRewrite = "没有可整理的文字。先输入或听写，再点润色。"
        public static let emptyRewriteEn = "There is no text to tidy. Type or dictate first, then tap rewrite."
        public static let demoFailedNote = "没有插入文字。"
        public static let demoFailedNoteEn = "Nothing was inserted."

        public static let systemSettings = "打开本 App 的系统设置"
        public static let systemSettingsEn = "Open this app’s Settings page"
        public static let systemSettingsNote = "这只会打开本 App 自己的系统设置页，不会跳到键盘列表。添加键盘请用上面的三步。"
        public static let systemSettingsNoteEn = "This opens this app’s own Settings page. It does not jump to the keyboard list. Use the three steps above to add the keyboard."

        public static let micTitle = "麦克风只在你点按时打开"
        public static let micTitleEn = "The microphone opens only when you tap it"
        public static let micBody = "演示关闭且已允许完全访问、麦克风和语音识别时，听写使用苹果的设备端识别，并要求识别留在本机。苹果并不保证键盘扩展里一定能打开麦克风。如果扩展打不开，请用本页的「本机听写」，或打开演示模式。录音不会被保存，也不会上传。"
        public static let micBodyEn = "With demo mode off and Full Access, microphone, and speech recognition allowed, dictation uses Apple’s on-device recognizer and refuses server recognition. Apple does not guarantee that a keyboard extension can open the microphone. If the extension cannot, use Dictate on device on this page, or turn demo mode on. Recordings are not stored and are not uploaded."

        public static let scopeTitle = "这一版接到哪一步"
        public static let scopeTitleEn = "What this build actually runs"
        public static let scopeItems: [(String, String)] = [
            ("语音：演示关闭时使用苹果设备端识别。没有 Whisper 运行时。", "Speech: Apple on-device recognition when demo mode is off. No Whisper runtime."),
            ("语气：润色、更短、正式、口语都在本机完成。系统提供 Apple Intelligence 时，试验台会先试 Foundation Models，失败就回到规则。", "Tone: polish, shorter, formal, and casual all run on device. When Apple Intelligence exposes Foundation Models, the playground tries that first and falls back to the rules."),
            ("没有内购、广告、追踪，也没有需要密钥的云端接口。", "No in-app purchase, ads, tracking, or cloud API that needs a key.")
        ]

        public static let idTitle = "签名用的标识"
        public static let idTitleEn = "Identifiers used for signing"
        public static let idFootnote = "主 App、键盘扩展和 App Group 已写成 com.mosquito1123.*。请在 Xcode Signing 里为 group.com.mosquito1123.keyboardapp 打开 App Groups。免费 Personal Team 若仍被拒绝，保持 KEYBOARD_APP_GROUP_ENABLED 为 NO：设置只留在本 App，键盘仍可安装运行。"
        public static let idFootnoteEn = "The app, keyboard, and App Group already use com.mosquito1123.*. Enable App Groups for group.com.mosquito1123.keyboardapp in Xcode Signing. If a free Personal Team still blocks the group, leave KEYBOARD_APP_GROUP_ENABLED set to NO: settings stay in this app, and the keyboard still installs."
        public static let runningAs = "当前 App 的 Bundle ID"
        public static let runningAsEn = "Bundle ID of this running app"

        public static let versionPrefix = "预览"
    }

    public enum Settings {
        public static let title = "设置"
        public static let intro = "语言和演示开关会尽量与键盘共享。没有 App Group 时，它们只保存在本 App 里。"
        public static let introEn = "Language and the demo switch are shared with the keyboard when an App Group is available. Without one, they stay in this app."
        public static let groupOn = "App Group 已可用。完全访问打开后，键盘能读到这里的选择。"
        public static let groupOnEn = "The App Group is available. After Full Access is on, the keyboard can read these choices."
        public static let groupOff = "App Group 未启用。这是免费 Personal Team 的默认路径：设置留在本 App，键盘使用自己的偏好，仍然可以听写和整理。"
        public static let groupOffEn = "The App Group is off. That is the free Personal Team default: settings stay in this app, the keyboard uses its own preferences, and dictation plus rewrite still run."

        public static let languageHeading = "语言偏好"
        public static let languageHeadingEn = "Language preference"
        public static let languageFootnote = "会切换演示例句、逗号和句号，以及设备端识别使用的语言（zh-CN、en-US、ja-JP）。没有单独的模型下载页。"
        public static let languageFootnoteEn = "This switches the demo sentence, the comma and period, and the on-device recognizer locale (zh-CN, en-US, ja-JP). There is no separate model-download screen."

        public static let demoHeading = "演示模式"
        public static let demoHeadingEn = "Demo mode"
        public static let demoToggle = "用本地示例代替听写和润色"
        public static let demoToggleEn = "Use local samples instead of dictation and tidy-up"
        public static let demoOnDetail = "打开时，麦克风和润色插入写在 App 里的文字，不申请麦克风，也不联网。适合审核或真机麦克风不可用时退回。"
        public static let demoOnDetailEn = "When this is on, the mic and rewrite controls insert text that ships with the app. They do not request the microphone or use the network. Use it for review, or when the microphone is unavailable."
        public static let demoOffDetail = "关闭时，麦克风使用苹果的设备端语音识别，需要完全访问、麦克风和语音识别权限。语气按钮始终在本机整理选中文字或刚听写的内容，不随演示开关改变。设备端识别不可用时不会改走云端。"
        public static let demoOffDetailEn = "When this is off, the mic uses Apple’s on-device speech recognition and needs Full Access plus microphone and speech permission. Tone buttons always rewrite the selection or the last dictation on device, whether or not demo mode is on. If on-device recognition is unavailable, it does not fall back to a server."
        public static let syncNote = "没打开完全访问时，键盘读不到这里的选择，改用内置演示：简体中文，演示开，不打开麦克风。"
        public static let syncNoteEn = "Without Full Access the keyboard cannot read this screen. It uses the built-in demo: Simplified Chinese, demo on, microphone closed."

        public static let privacyHeading = "隐私说明"
        public static let privacyHeadingEn = "Privacy notes"
        public static let privacyItems: [(String, String)] = [
            ("离线优先：没有账号，没有自己的服务器，也不做追踪或广告。", "Offline-first: no account, no server of our own, and no tracking or advertising."),
            ("润色、更短、正式和口语都在本机处理。能用 Apple Intelligence 时也不离开这台设备。", "Polish, shorter, formal, and casual all run on this device. Apple Intelligence, when it is available, stays on device too."),
            ("听写音频只在本机交给苹果的设备端识别，不保存录音，也不上传。", "Dictation audio is handed only to Apple’s on-device recognizer. Recordings are not stored and not uploaded."),
            ("若该语言不能在本机识别，听写会停止，不会改用云端识别。", "If that language cannot be recognized on device, dictation stops. It does not switch to server recognition."),
            ("系统第一次使用某种语言时，可能会自行下载该语言的听写资源。那是 iOS 的行为，不是本 App 的上传。", "The first time a language is used, iOS may download that language’s dictation assets. That is iOS, not an upload from this app."),
            ("完全访问用来同步上面的设置，并在演示关闭时允许键盘打开麦克风。不用来上传内容。", "Full Access syncs the settings above and, with demo mode off, lets the keyboard open the microphone. It is not used to upload content."),
            ("演示句子是编译进 App 的文本，不是录音结果。", "Demo sentences are text compiled into the app, not a recording.")
        ]

        public static let permissionHeading = "麦克风和语音识别"
        public static let permissionHeadingEn = "Microphone and speech recognition"
        public static let permissionIntro = "请在主 App 里授权。键盘扩展里的系统提示不一定弹得出来。拒绝之后可以去系统设置里重新打开。"
        public static let permissionIntroEn = "Grant access in this app. The system prompt is not reliable inside the keyboard extension. If you deny it, you can turn it back on in Settings."
        public static let permissionSpeech = "语音识别"
        public static let permissionSpeechEn = "Speech recognition"
        public static let permissionMic = "麦克风"
        public static let permissionMicEn = "Microphone"
        public static let permissionModel = "当前语言的设备端识别"
        public static let permissionModelEn = "On-device recognition for this language"
        public static let permissionRequest = "检查并请求权限"
        public static let permissionRequestEn = "Check and request access"
        public static let permissionSettings = "打开本 App 的系统设置"
        public static let permissionSettingsEn = "Open this app’s Settings"
        public static let permissionReady = "可以本机听写"
        public static let permissionReadyEn = "On-device dictation is available"
        public static let permissionNotReady = "还不能本机听写"
        public static let permissionNotReadyEn = "On-device dictation is not available yet"

        public static func permissionState(_ speech: SpeechPermissionState) -> (String, String) {
            switch speech {
            case .authorized:
                return ("已允许", "Allowed")
            case .notDetermined:
                return ("未询问", "Not asked")
            case .denied:
                return ("已拒绝", "Denied")
            case .restricted:
                return ("受限制", "Restricted")
            case .unavailable:
                return ("此系统不可用", "Unavailable on this system")
            }
        }

        public static func microphoneState(_ microphone: MicrophonePermissionState) -> (String, String) {
            switch microphone {
            case .granted:
                return ("已允许", "Allowed")
            case .undetermined:
                return ("未询问", "Not asked")
            case .denied:
                return ("已拒绝", "Denied")
            case .unavailable:
                return ("此系统不可用", "Unavailable on this system")
            }
        }

        public static func modelState(supported: Bool?) -> (String, String) {
            switch supported {
            case .some(true):
                return ("可用", "Available")
            case .some(false):
                return ("不可用，不会改走云端", "Unavailable, and we will not use a server")
            case .none:
                return ("尚未检查", "Not checked")
            }
        }

        public static let limitsHeading = "边界"
        public static let limitsHeadingEn = "Limits"
        public static let stubItems: [(String, String)] = [
            ("没有内购、广告或追踪。ProductPolicy 里这几项都是关闭的。", "No in-app purchase, ads, or tracking. Those ProductPolicy flags stay off."),
            ("键盘上的语气按钮用本机规则。试验台在 iOS 26 且 Apple Intelligence 可用时会先问系统模型，否则用同一套规则。", "Tone buttons on the keyboard use on-device rules. On iOS 26 with Apple Intelligence available, the playground asks the system model first, then uses the same rules."),
            ("没有 Whisper、llama 或其他需要单独下载的运行时。", "There is no Whisper, llama, or other downloadable runtime."),
            ("字母键仍是占位布局，不是中文输入法。语言只有简体中文、英语和日语。", "Letter keys are still a placeholder layout, not a Chinese input method. Languages are Simplified Chinese, English, and Japanese.")
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
        public static let voiceListeningTitle = "正在听写"
        public static let voiceListeningDetail = "请说话。只在本机识别。再点一次结束，停顿后也会结束。"
        public static let voiceRequestingTitle = "正在请求权限"
        public static let voiceRequestingDetail = "请允许麦克风和语音识别。若看不到提示，打开主 App 的设置。"
        public static let voiceFinishingTitle = "正在结束"
        public static let voiceFinishingDetail = "正在完成本机识别…"
        public static let voiceWorkingTitle = "正在准备示例"
        public static let voiceWorkingDetail = "稍等，将插入本地示例。不会录音。再点一次可取消。"
        public static let voiceDoneTitle = "已插入听写"
        public static let voiceDoneDemoTitle = "已插入示例"
        public static let voiceCancelled = "已取消，没有插入文字。"
        public static let voiceEmptyTitle = "没有听到内容"
        public static let voiceEmptyDetail = "没有识别到文字，输入框未改动。"
        public static let voiceUnwiredTitle = "识别不可用"
        public static let voiceFailedTitle = "没有插入"
        public static let voiceFailedDetail = "听写没有完成。可以再试，或打开演示模式。"
        public static let rewriteTitle = "润色"
        public static let rewriteWorkingDetail = "正在本机处理选中文字或刚听写的内容，不会上传。"
        public static let rewriteEmptyTitle = "没有可整理的文字"
        public static let rewriteEmptyDetail = "没有选中文字，光标前也没有内容。先输入、听写或选中一段。"
        public static let rewriteFailedDetail = "整理没有完成，输入框未改动。"

        public static func rewriteWorkingTitle(_ tone: RewriteTone) -> String {
            switch tone {
            case .polish:
                return "正在润色"
            case .shorter:
                return "正在缩短"
            case .formal:
                return "正在改为正式"
            case .casual:
                return "正在改为口语"
            }
        }

        public static func rewriteDoneTitle(_ tone: RewriteTone) -> String {
            switch tone {
            case .polish:
                return "已润色"
            case .shorter:
                return "已缩短"
            case .formal:
                return "已改为正式"
            case .casual:
                return "已改为口语"
            }
        }
        public static let space = "空格"
        public static let micHint = "听写"
        public static let micDemoHint = "语音示例"
        public static let rewriteHint = "本机整理"
        public static let rewriteDemoHint = "示例润色"

        public static func speechFailure(for failure: SpeechFailure) -> (title: String, detail: String) {
            switch failure {
            case .notImplemented:
                return (voiceUnwiredTitle, "这套系统没有接上设备端识别。可打开演示模式。")
            case .speechNotDetermined:
                return (voiceRequestingTitle, "还没有完成授权。请打开主 App，在设置里允许语音识别。")
            case .speechDenied:
                return (voiceFailedTitle, "语音识别已被拒绝。请到系统设置里为本 App 打开，或改用演示模式。")
            case .speechRestricted:
                return (voiceFailedTitle, "这台设备限制了语音识别，无法听写。")
            case .microphoneDenied:
                return (voiceFailedTitle, "麦克风已被拒绝。请到系统设置里允许，或打开演示模式。")
            case .onDeviceUnavailable:
                return (voiceUnwiredTitle, "当前语言不能在本机识别。不会改用云端。可换语言，或打开演示模式。")
            case .recognizerUnavailable:
                return (voiceUnwiredTitle, "识别器暂不可用。请稍后再试，或打开演示模式。")
            case .audioSessionFailed(let code):
                let suffix = code == 0 ? "" : "（\(code)）"
                return (voiceFailedTitle, "键盘里打不开麦克风\(suffix)。请用主 App 的本机听写，或打开演示模式。")
            case .noSpeech:
                return (voiceEmptyTitle, voiceEmptyDetail)
            case .interrupted:
                return (voiceFailedTitle, voiceFailedDetail)
            }
        }
        public static let globeHint = "切换键盘"
        public static let deleteHint = "删除"
        public static let returnHint = "换行"
        public static let shiftHint = "大小写"
        public static let planeDigitsHint = "数字"
        public static let planeLettersHint = "字母"

        public static func idleDetail(language: TypingLanguage, demoEnabled: Bool, synced: Bool, shared: Bool) -> String {
            if !synced {
                return "完全访问未开，使用内置演示，不会录音。语气按钮仍在本机整理当前文字。"
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
            if !shared && demoEnabled {
                return "\(name) · 演示开。设置未共享。点麦克风插入示例。"
            }
            if !shared {
                return "\(name) · 本机听写。设置未共享，使用键盘自己的偏好。"
            }
            if demoEnabled {
                return "\(name) · 演示开。点麦克风插入示例，不会录音。"
            }
            return "\(name) · 本机听写。点麦克风说话，音频不上传。"
        }
    }

    public enum Playground {
        public static let title = "AI 试验台"
        public static let titleEn = "AI playground"
        public static let intro = "在这里听写，再用润色、更短、正式或口语整理整段文字。不用离开本 App，也不会做追踪。"
        public static let introEn = "Dictate here, then polish, shorten, or change tone. You stay in this app, and nothing is tracked."
        public static let privacy = "能在本机完成的步骤都留在本机。没有账号，没有统计，也不会把文字发到我们的服务器。"
        public static let privacyEn = "Steps that can run on device stay on device. There is no account, no analytics, and no upload to a server of ours."
        public static let open = "打开 AI 试验台"
        public static let openEn = "Open the AI playground"
        public static let placeholder = "输入、粘贴，或点下面的听写"
        public static let dictate = "听写到这里"
        public static let dictateEn = "Dictate into this field"
        public static let demoNote = "演示模式只影响听写。语气整理始终在本机进行。"
        public static let demoNoteEn = "Demo mode only affects dictation. Tone rewrite always stays on device."
        public static let intelligenceOn = "Apple Intelligence 的系统模型可用，整理会先用它。"
        public static let intelligenceOnEn = "The Apple Intelligence system model is available. Rewrite tries it first."
        public static let intelligenceOff = "系统模型不可用。整理使用本机规则。iOS 18 没有公开的 Foundation Models 接口，iOS 26 且打开 Apple Intelligence 后才会用到。"
        public static let intelligenceOffEn = "The system model is unavailable. Rewrite uses on-device rules. iOS 18 has no public Foundation Models API; that path starts on iOS 26 with Apple Intelligence on."
        public static let empty = "先输入或听写一段文字，再选择语气。"
        public static let emptyEn = "Type or dictate something, then pick a tone."
        public static let failed = "没有改写。原文还在。"
        public static let failedEn = "Nothing was rewritten. The original text is unchanged."

        public static func engineLine(_ name: String) -> String {
            switch name {
            case "apple-foundation-model":
                return "本次使用 Apple Intelligence（本机）· \(name)"
            case "on-device-tone":
                return "本次使用本机语气规则 · \(name)"
            case "on-device-tidy":
                return "本次使用本机整理 · \(name)"
            case "demo-fixture":
                return "本次使用内置示例 · \(name)"
            default:
                return "本次引擎 · \(name)"
            }
        }
    }
}
