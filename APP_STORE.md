# App Store readiness / 上架准备

Version **0.4.0** (build 4). This is an engineering checklist for a later App Store Connect upload. It does not upload a build or create an app record. Bundle IDs are already `com.mosquito1123.*`.

这一版是上架前的工程清单，不是向 App Store Connect 上传构建。Bundle ID 已经是 `com.mosquito1123.*`。

The app is original MIT code. It does not vendor Sayboard or any other GPL project. Sayboard is mentioned only as product direction. See the README for the difference table.

---

## 1. Confirm the identifiers / 确认标识

Do this before signing, archiving, or TestFlight. The extension ID must stay a child of the app ID. These values are already filled in. Change them only if your team cannot register this prefix.

签名、归档或 TestFlight 之前先核对。扩展 ID 必须是主 App ID 加后缀。下面的值已经写好。只有当你的 Team 注册不了这个前缀时才需要改。

| What | Identifier | Where |
| --- | --- | --- |
| Containing app | `com.mosquito1123.keyboardapp` | `project.yml` (`PRODUCT_BUNDLE_IDENTIFIER`) and the KeyboardApp target in `KeyboardApp.xcodeproj` |
| Keyboard extension | `com.mosquito1123.keyboardapp.keyboard` | Same, KeyboardExtension target |
| App Group | `group.com.mosquito1123.keyboardapp` | `KeyboardApp/KeyboardApp.entitlements`, `KeyboardExtension/KeyboardExtension.entitlements` |
| In-app copy of those IDs | the three strings above | `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift` |
| URL name | `com.mosquito1123.keyboardapp` | `KeyboardApp/Info.plist` → `CFBundleURLTypes` → `CFBundleURLName` |

The URL scheme `keyboardapp://` is reserved and unused. Dictation does not open it. The URL name already matches `com.mosquito1123.keyboardapp`.

`keyboardapp://` 只是预留，听写不会打开它。URL name 已经是 `com.mosquito1123.keyboardapp`。

After editing `project.yml`:

```bash
brew install xcodegen
xcodegen generate
```

Opening `KeyboardApp.xcodeproj` does not require XcodeGen until you change the spec. Shared schemes:

- **KeyboardApp** — runs the app and embeds the extension. Use this for Archive.
- **KeyboardExtension** — asks which app to launch. Use it to debug the keyboard.

Both live in `KeyboardApp.xcodeproj/xcshareddata/xcschemes/` and are shared.

### App Group

Enable the App Groups capability for `group.com.mosquito1123.keyboardapp` on both App IDs before you expect settings to sync. The default Xcode project does **not** sign that entitlement (`KEYBOARD_APP_GROUP_ENABLED` = `NO`, Code Signing Entitlements = `*.NoAppGroup.entitlements`), so a free Personal Team can install.

- **Paid Apple Developer Program:** register `group.com.mosquito1123.keyboardapp`, set `KEYBOARD_APP_GROUP_ENABLED` to `YES`, and point both targets at `KeyboardApp.entitlements` and `KeyboardExtension.entitlements`.
- **Free Personal Team:** if signing still reports that the application group is not available, leave the default. Preferences stay in-process (`UserDefaults.standard`). The keyboard keeps its own defaults and can still dictate and run tone actions. Uncomment `.define("KEYBOARD_APP_GROUP_DISABLED")` in `Package.swift` only if you need to force that path in the shared package as well.

为 `group.com.mosquito1123.keyboardapp` 打开 App Groups 之后，设置才能在两个进程之间同步。默认工程不签名这项能力，免费 Personal Team 可以直接装到真机。付费账号注册 group 后，把 `KEYBOARD_APP_GROUP_ENABLED` 设为 `YES`，并把两个 target 的 entitlements 指到带 group 的文件。免费账号若仍被拒绝，保持默认即可：偏好留在本进程，键盘仍可听写和做语气整理。

## 2. Required capabilities / 需要的能力

Turn these on only as listed. Do not add Push, iCloud, Sign in with Apple, Associated Domains, or In-App Purchase. None of those are implemented, and `ProductPolicy` keeps purchases, ads, and tracking off.

| Capability | Needed | Notes |
| --- | --- | --- |
| App Group | Optional at runtime, required only to sync settings | `group.com.mosquito1123.keyboardapp`. Default signing omits it (`*.NoAppGroup.entitlements`) |
| Custom keyboard extension | Yes | `NSExtensionPointIdentifier` = `com.apple.keyboard-service` |
| Allow Full Access | Yes | `RequestsOpenAccess` is `true` in `KeyboardExtension/Info.plist`. It is not an entitlement |
| Microphone | Yes | `NSMicrophoneUsageDescription` on the app and the extension |
| Speech recognition | Yes | `NSSpeechRecognitionUsageDescription` on the app and the extension |
| On-device speech only | Yes, in code | `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`. No server retry |
| Network client, analytics, StoreKit, ads | No | Do not add them for this submission |
| Export compliance | Already set | `ITSAppUsesNonExemptEncryption` is `false`. This app does not add its own encryption |

Frameworks in use are system frameworks (`Speech`, `AVFoundation`, `NaturalLanguage`), imported by `KeyboardShared`. The containing app also imports `FoundationModels` when the SDK includes it, and only calls it when Apple's on-device system model is available. They are not vendored binaries.

## 3. Privacy / 隐私

### Nutrition label answers

Use **Data Not Collected** in App Store Connect.

- Data used to track you: none. `NSPrivacyTracking` is false. There is no tracking domain and no App Tracking Transparency prompt.
- Data linked to the user: none.
- Data not linked to the user: none.

Microphone audio, the dictated string, and tone rewrites are processed on device. They are not stored and not sent by this app. Apple’s privacy questionnaire treats data as collected when it leaves the device. This app does not do that. If on-device recognition is unavailable, dictation stops. It does not fall back to Apple’s server recognizer. Tone presets use local rules. On iOS 26 the playground may call Apple's on-device Foundation Models API; if that model is unavailable, the same rules run. There is no tracking.

iOS itself may download a dictation asset the first time a language is used. That is the system, not a request from this app. Say so in the review notes if you are asked.

在 App Store Connect 里选 **不收集数据**。麦克风音频和听写结果只在本机用于插入文字，不保存、不上传。设备端识别不可用时会停止，不会改走云端识别。系统第一次使用某种语言时可能会自行下载听写资源，那是 iOS，不是本 App 发出的请求。

### Privacy manifest

`KeyboardApp/PrivacyInfo.xcprivacy` and `KeyboardExtension/PrivacyInfo.xcprivacy`:

- `NSPrivacyTracking` = false
- `NSPrivacyCollectedDataTypes` = empty
- `NSPrivacyAccessedAPICategoryUserDefaults` with reasons **CA92.1** (app-private defaults) and **1C8F.1** (App Group shared with the extension)

No other required-reason API categories are used (no disk-space, boot-time, file-timestamp, or active-keyboard queries).

### Permission strings

Both Info.plists carry Chinese and English usage strings for the microphone and for speech recognition. The system alert shows that text. Keep it accurate: on-device dictation, no upload, no stored recording, no server fallback.

## 4. Screenshots to capture / 需要的截图

Capture on a real device when you can. The keyboard extension’s microphone is the path most likely to differ from the Simulator. Follow the sizes App Store Connect asks for on the day you upload. Because `TARGETED_DEVICE_FAMILY` is iPhone and iPad, prepare both if you leave iPad enabled.

在真机上截。键盘扩展里的麦克风最可能和模拟器不一致。尺寸以你上传当天 App Store Connect 的要求为准。工程同时包含 iPhone 和 iPad，如果不上架 iPad，就在提交前从 target 里拿掉。

Suggested frames:

1. Home screen of **键盘项目**: the three enablement steps.
2. The Full Access card (“会用到 / 这一版不会”), scrolled so both columns are readable.
3. Settings with demo mode **off**, showing language, the permission card, and the privacy notes.
4. Settings with demo mode **on**, so review can see the fallback.
5. The in-app text field after a successful on-device dictation (demo off, permissions allowed).
6. The AI playground after **润色** or **更短**, showing the rewritten text and the on-device engine line, with no “演示润色” label.
7. The keyboard inside another app (Notes is fine): letter rows, globe key, voice strip, and the 润色 / 更短 / 正式 strip.
8. The voice strip while listening, then after text is inserted.
9. A denied or “on-device unavailable” voice-strip state, if you can produce it without private data in the field.
10. iPad versions of 1, 3, and 7 if you ship iPad.

Do not put account data, other people’s messages, or a microphone recording indicator from a different app into the shots. The orange system mic indicator in the status bar is fine and helps explain the feature.

## 5. Review notes / 审核备注

Paste the English block into App Review Information. The Chinese block is the same content if you also keep notes locally.

### English (paste this)

```
键盘项目 (KeyboardApp) is a third-party system keyboard. There is no account, no in-app purchase, no ads, and no analytics.

How to test:
1. Install the build. Open 键盘项目.
2. Settings → General → Keyboard → Keyboards → Add New Keyboard → 键盘项目.
3. Tap 键盘项目 again and turn on Allow Full Access. The app’s home screen lists what that switch is used for (read the language and demo setting; open the microphone only when demo mode is off) and what it does not do (no upload, no server speech recognition, no tracking, no stored recording).
4. In the app’s Settings, tap “Check and request access” and allow Microphone and Speech Recognition.
5. Demo mode is OFF by default. Focus the text field on the home screen and tap “Dictate on device”, or switch to this keyboard in any text field and tap the microphone. Speech stays on device (SFSpeechRecognizer requiresOnDeviceRecognition). A second tap, a pause, or a short time limit ends listening. Nothing is uploaded.
6. Tap 润色, 更短, or 正式 on the keyboard (selection, last dictation, or a short suffix). Or open AI playground in the app for 润色 / 更短 / 正式 / 口语. Rewrite stays on device. On iOS 26, the playground uses Apple Foundation Models when Apple Intelligence is available, and otherwise the on-device rules. It does not track you or upload the text.
7. Turn Demo mode ON to insert a bundled sample sentence instead. Demo mode does not open the microphone.

If the keyboard extension cannot open the microphone, the voice strip says so and does not insert text. Please use “Dictate on device” inside the app. Apple does not guarantee microphone capture inside a custom keyboard even with Full Access.

On-device recognition depends on the selected language (zh-CN, en-US, ja-JP) and on Apple’s on-device speech assets. If those assets are unavailable, dictation stops. We do not fall back to server recognition. The letter keys are a placeholder QWERTY layout, not a Chinese input method.

ITSAppUsesNonExemptEncryption is false. Privacy nutrition label: Data Not Collected.
```

### 中文

```
键盘项目是第三方系统键盘。没有账号、内购、广告或统计。

测试步骤：
1. 安装后打开「键盘项目」。
2. 设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 键盘项目。
3. 再点一次「键盘项目」，打开「允许完全访问」。主页写明这个开关会做什么（读取语言和演示开关；仅在演示关闭时打开麦克风）以及不会做什么（不上传、不走云端识别、不追踪、不保存录音）。
4. 在 App 的「设置」里点「检查并请求权限」，允许麦克风和语音识别。
5. 演示模式默认关闭。在主页输入框点「本机听写」，或在任意输入框切到本键盘后点麦克风。识别要求留在本机。再点一次、停顿，或到达时间上限都会结束。不会上传。
6. 在键盘上点「润色」「更短」或「正式」（选区、刚听写的文字，或光标前一小段）。也可以打开主 App 的「AI 试验台」试用润色、更短、正式、口语。整理留在本机。iOS 26 且 Apple Intelligence 可用时，试验台会先用 Foundation Models，否则用本机规则。不会追踪，也不会上传文字。
7. 打开「演示模式」后，麦克风只插入内置例句，不会打开麦克风。

如果键盘扩展打不开麦克风，语音条会说明原因，并且不改输入框。请改用主 App 里的「本机听写」。即使打开了完全访问，苹果也不保证自定义键盘一定能录音。

设备端识别取决于所选语言（zh-CN、en-US、ja-JP）以及系统是否已准备该语言的本机听写资源。资源不可用时听写会停止，不会改走服务器。字母键是占位的 QWERTY，不是中文输入法。

ITSAppUsesNonExemptEncryption 为 false。隐私营养标签：不收集数据。
```

## 6. TestFlight / 测试

1. Select your Team on both targets. Keep `com.mosquito1123.keyboardapp` unless you must claim a different prefix.
2. For a paid team, register `group.com.mosquito1123.keyboardapp`, set `KEYBOARD_APP_GROUP_ENABLED` to YES, and switch both entitlements files. A Personal Team can archive with the default NoAppGroup entitlements.
3. Scheme **KeyboardApp**, destination **Any iOS Device (arm64)**, configuration **Release**.
4. Product → Archive. The extension is embedded by the app target (`SKIP_INSTALL` is YES on the extension, so it is not a separate archive product).
5. Distribute → TestFlight. Answer export compliance with the existing `ITSAppUsesNonExemptEncryption` = false (no non-exempt encryption added by the app).
6. On a device that is not your daily driver if you can: install, add the keyboard, allow Full Access, grant microphone and speech recognition, dictate in the app, then dictate from the keyboard in Notes.
7. Turn demo mode on and confirm the mic inserts the sample sentence and does not show the system recording indicator.
8. Deny microphone permission and confirm the voice strip explains the denial and does not insert text.
9. Crash logs and the voice-strip audio error code (if the extension cannot start a session) are the signal for whether keyboard recording works on that OS version.

模拟器可以看界面和演示模式。麦克风和语音识别请在真机上测。

## 7. Known limitations / 已知限制

- Bundle IDs are `com.mosquito1123.*`. A Personal Team can run without the App Group. Settings sync needs the group entitlement turned on.
- Letter keys are QWERTY. This is not a Chinese, Japanese, or English input method and does not offer candidates.
- Only three language preferences: Simplified Chinese (`zh-CN`), English (`en-US`), Japanese (`ja-JP`).
- Tone rewrite is an on-device heuristic (polish, shorter, formal, casual). The containing app may call Apple's Foundation Models on iOS 26 when the system model is available, and falls back to the heuristic. The keyboard extension does not link that framework. Empty text shows an empty state and inserts nothing. Nothing is tracked.
- Dictation ends on a second tap, after about 1.6 seconds of silence once speech has started, after 6 seconds with no speech, or at 18 seconds.
- `requiresOnDeviceRecognition` is always set. There is no server fallback and no WhisperKit / llama.cpp / other GPL runtime, optional or otherwise.
- A custom keyboard is not guaranteed to be allowed to record. If `AVAudioSession` fails, the strip shows the error code and leaves the field unchanged. The containing app’s dictate button is the reliable path.
- Without Full Access, the keyboard ignores Settings and uses the built-in demo. It does not open the microphone.
- The first use of a language may require iOS to download on-device speech assets. This app does not implement its own model download screen.
- No account, no iCloud sync, no purchase, no support inbox, and no crash reporter are included.
- `recognizeOnce()` and `complete(prompt:)` still throw `notImplemented`. They are legacy entry points. The keyboard uses `SpeechEngines` and `RewriteEngines`.

## 8. Pre-upload checklist / 提交前勾选

- [ ] Bundle IDs and `AppIdentity.swift` match, and the App Group is either registered or left off for a Personal Team
- [ ] Both targets sign with your Team
- [ ] Archive of scheme **KeyboardApp** succeeds
- [ ] Usage strings still describe on-device dictation and no upload
- [ ] Privacy manifests still say no tracking and no collected data types
- [ ] App Store Connect privacy answers: Data Not Collected
- [ ] Review notes pasted
- [ ] Screenshots include enablement, Full Access, Settings, and the keyboard
- [ ] TestFlight device passed: allow permissions, dictate, tidy, demo fallback, permission denied
- [ ] No GPL model runtime and no analytics or purchase SDK added
