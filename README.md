# 键盘项目 / KeyboardApp

Original iOS system keyboard. MIT license. Version **0.4.0**. Deployment target **iOS 17**. Open with **Xcode 16** or newer.

The home-screen name is **键盘项目**. Bundle IDs are already set to a Personal Team–friendly prefix (the App Store checklist is [APP_STORE.md](APP_STORE.md)):

| Role | Identifier |
| --- | --- |
| Containing app | `com.mosquito1123.keyboardapp` |
| Keyboard extension | `com.mosquito1123.keyboardapp.keyboard` |
| App Group | `group.com.mosquito1123.keyboardapp` |

This repository is not a fork. It does not include code, assets, bundle identifiers, strings, or license text from any other keyboard project.

Shared schemes **KeyboardApp** and **KeyboardExtension** are in `KeyboardApp.xcodeproj`. Archive the **KeyboardApp** scheme. It embeds the extension.

---

## English

### What this build does

- A system keyboard extension you can switch to from a text field in other apps.
- A SwiftUI app with a three-step enablement guide, a Full Access explanation, and Settings.
- A UIKit keyboard: QWERTY letter rows, a digit plane, shift, delete, space, return, a globe key, and a voice strip.
- **On-device dictation** when demo mode is off, Full Access is on, and microphone plus speech recognition are allowed. The recognizer is Apple's `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`. Audio is not uploaded and not stored. If on-device recognition is unavailable, dictation stops. It does not call a server.
- **Demo mode** (off by default, still in Settings) inserts a bundled sample sentence and does not open an audio session. Without Full Access the keyboard cannot read Settings and uses that built-in demo. Demo mode does not change tone rewrite.
- **Tone rewrite** offers 润色 / 更短 / 正式 (and 口语 in the app). The keyboard applies them to the selection, otherwise to the last dictated text, otherwise to a short suffix before the cursor. The pass is an on-device heuristic (`NLTagger` / `NLTokenizer` for the tidy step on Apple platforms). The in-app playground tries Apple's Foundation Models API when the OS provides it (iOS 26 with Apple Intelligence) and falls back to the same heuristics. Nothing is tracked and nothing is uploaded to a server of ours.
- A language preference with three entries. It selects the demo sentence, the comma and period keys, and the speech locale (`zh-CN`, `en-US`, `ja-JP`).
- Settings stored in the App Group when that capability is provisioned. Otherwise they stay in-process. The extension reads shared settings only when Allow Full Access is on and the group exists.
- An **AI playground** in the main app for dictation plus tone rewrite without leaving the app.
- No account, analytics, advertising, or in-app purchase. `ProductPolicy` keeps those flags off.

Letter keys are a placeholder layout. They are not a Chinese, Japanese, or English input method.

### App Store path

[APP_STORE.md](APP_STORE.md) is the bilingual checklist: which IDs to replace, capabilities, privacy nutrition-label answers, screenshots, paste-ready review notes, TestFlight steps, and known limitations. This repository does not upload a build.

### Relationship to Sayboard

[Sayboard](https://github.com/stanlsv/sayboard) is a separate, GPL-3 voice keyboard. This project only borrows product ideas from that public description:

- a keyboard that works inside other apps
- guidance for turning the keyboard on and for Full Access
- on-device speech recognition
- on-device rewriting of dictated text
- an offline posture: no account and no tracking

Nothing here is taken from that repository. WhisperKit, llama.cpp, and other GPL model runtimes are not linked, not optional, and not downloaded.

| | KeyboardApp | Sayboard (product, not source) |
| --- | --- | --- |
| License | MIT. No GPL files are vendored. | GPL-3 |
| Name and IDs | 键盘项目 / KeyboardApp, `com.mosquito1123.keyboardapp` | Their own name and identifiers |
| UI | Warm ink theme, our own copy, a letter-row placeholder plus a voice strip | Their own screens |
| Speech | Apple `SFSpeechRecognizer`, on-device only, plus a demo-sample toggle | Their own on-device engines and model downloads |
| Rewrite | On-device tone presets (polish, shorter, formal, casual). Optional Apple Foundation Models in the app when iOS 26 provides them. | On-device language-model rewriting |
| Languages | Three preferences, mapped to zh-CN / en-US / ja-JP | A large language list |
| Purchase and support mail | Not included. Tracking and ads are off. | Part of that product |
| Layout of code | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | Their own project |

`recognizeOnce()` and `complete(prompt:)` still throw `notImplemented`. They are legacy entry points. The keyboard calls `SpeechEngines` and `RewriteEngines`.

### Limits that are still real

- The letter layout is not an input method
- Tone rewrite shortens or restyles wording with local rules. It does not invent facts. The keyboard does not link Foundation Models.
- No model-download screen. iOS may download its own dictation assets the first time a language is used
- Apple does not guarantee that a keyboard extension can record, even with Full Access. If the audio session fails, the voice strip shows the error and the field is unchanged. Dictate from the containing app instead
- No cloud API and no in-app purchase
- Shared settings reach the keyboard only when Full Access is on and `KEYBOARD_APP_GROUP_ENABLED` is YES. The default build runs without an App Group.

`Packages/KeyboardShared` can be checked without Xcode:

```bash
cd Packages/KeyboardShared
swift test
```

### Requirements

- A Mac with Xcode 16 or newer
- iOS 17 Simulator, or an iPhone / iPad running iOS 17 or newer
- An Apple ID added in Xcode → Settings → Accounts

Signing, the Simulator, and the Settings app all happen on a Mac. Speech recognition needs a device if you want to hear the microphone path. The Simulator can still show the UI, the demo toggle, and permission copy.

### 1. Open the project

```bash
open KeyboardApp.xcodeproj
```

`project.yml` is the XcodeGen spec. You do not need XcodeGen to open the checked-in project. After you edit `project.yml`, regenerate with:

```bash
brew install xcodegen
xcodegen generate
```

New Swift files under `KeyboardApp/` and `KeyboardExtension/` must be added to the Xcode target. The shared package compiles every file in its source directory, including the iOS-only speech file.

### 2. Set the team

1. Select the **KeyboardApp** project, then the **KeyboardApp** target → **Signing & Capabilities**.
2. Choose your **Team**. Repeat for the **KeyboardExtension** target.
3. Leave the bundle IDs as they are, unless that prefix is already taken on your team:
   - App: `com.mosquito1123.keyboardapp`
   - Keyboard: `com.mosquito1123.keyboardapp.keyboard`
   - App Group: `group.com.mosquito1123.keyboardapp`

The extension ID stays a child of the app ID. The same strings live in `project.yml`, `AppIdentity.swift`, `KeyboardApp/Info.plist` (URL name), and the App Group entitlements files. The checked-in project signs **without** the App Group so a device install does not stop on a missing group. Details are in the next section and in [APP_STORE.md](APP_STORE.md).

### 3. App Group (signing)

You must enable the App Groups capability for `group.com.mosquito1123.keyboardapp` in [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) and in Xcode → Signing & Capabilities before the two processes can share settings. Register the group, add it to both App IDs, then:

1. Set the project build setting **`KEYBOARD_APP_GROUP_ENABLED`** to **`YES`** (it is `NO` by default). That value is written into both Info.plists as `KeyboardAppGroupEnabled`.
2. On **both** targets, change **Code Signing Entitlements** from the `*.NoAppGroup.entitlements` file to:
   - `KeyboardApp/KeyboardApp.entitlements`
   - `KeyboardExtension/KeyboardExtension.entitlements`

Those two files already contain `group.com.mosquito1123.keyboardapp`.

**Free Personal Team:** App Groups are often still rejected (`Application Group ... is not available`). Leave `KEYBOARD_APP_GROUP_ENABLED` at **`NO`** and leave the NoAppGroup entitlements in place. That is the default, and it is enough to run on a device:

- The app stores language and demo mode in its own `UserDefaults` (in-process). The keyboard does not see those values.
- With Full Access, the keyboard uses its own defaults (Simplified Chinese, demo mode off) and can still dictate and run 润色 / 更短 / 正式.
- Without Full Access, the keyboard keeps the built-in demo and does not open the microphone. Tone buttons still rewrite text that is already in the field.
- The AI playground in the main app does not need the group.

To force the in-process path even if a container exists, uncomment `.define("KEYBOARD_APP_GROUP_DISABLED")` in `Packages/KeyboardShared/Package.swift` and rebuild. `SharedStore.usesAppGroup` is the runtime check: it is false when the Info.plist flag is `NO`, when that compile flag is set, or when `containerURL(forSecurityApplicationGroupIdentifier:)` is nil.

`RequestsOpenAccess` is not an entitlement. It lives in `KeyboardExtension/Info.plist` and is already `true`.

### 4. Run

**Simulator**

1. Scheme **KeyboardApp**, destination any iOS 17+ simulator.
2. Run. The app shows the enablement steps, Settings, and a text field.
3. In Settings, leave demo mode off to exercise permission copy, or turn it on to insert the sample with no microphone.
4. If the software keyboard is hidden: **I/O → Keyboard → Toggle Software Keyboard** (or press ⌘K).

**Device**

1. Destination: your iPhone or iPad.
2. On the device, turn on **Settings → Privacy & Security → Developer Mode** if iOS asks, then trust the developer certificate.
3. Run the **KeyboardApp** scheme so the app and the embedded extension install together.
4. In the app’s Settings, tap **检查并请求权限** and allow the microphone and speech recognition.
5. With demo mode off, tap **本机听写** in the text field, or open **AI 试验台** and dictate there. **润色 / 更短 / 正式 / 口语** rewrite that text on device. On the keyboard, the same three actions (without 口语) use the selection or the last dictated text.

To debug the extension itself, use the **KeyboardExtension** scheme. Xcode asks which app to launch. Pick **键盘项目** or any app with a text field, after the keyboard has been added in Settings.

### 5. Enable the keyboard and Full Access

1. **Settings → General → Keyboard → Keyboards → Add New Keyboard**.
2. Under third-party keyboards, choose **键盘项目**.
3. Tap **键盘项目** again and turn on **Allow Full Access**. iOS shows Apple’s standard warning. This build does not upload keystrokes or audio. Demo mode does not record. On-device dictation records only while you are listening, then discards the audio.
4. Focus a text field. Tap the globe key and select **键盘项目**.
5. On the voice strip, tap the microphone.
   - Demo on, or Full Access off: a sample sentence appears. The title says it is a sample. Tap again during the wait to cancel.
   - Demo off and Full Access on: speak. A second tap ends listening and inserts the transcript. A pause does the same. Permission problems, an unavailable on-device model, and an audio-session failure each leave the field unchanged and explain why.
6. **润色**, **更短**, and **正式** with an empty field show an empty state. With a selection, they replace that selection. Otherwise they replace the last dictated text when it is still before the cursor, or about 160 characters before the cursor. Demo mode does not turn these into a labeled sample.

`RequestsOpenAccess` is `true`, which is what makes the Allow Full Access switch appear. Letter keys still type when the switch is off. Until it is on, the voice strip says it is using the built-in demo and is not reading the app’s settings.

Basic typing does not need the network. This build does not contact a server of its own.

### 6. Microphone

`NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` are on both the app and the extension, in Chinese and English. Grant the prompts from the containing app. A keyboard extension cannot be relied on to present them.

Confirm on a **device** whether the extension process can capture audio. If it cannot, the strip reports the `AVAudioSession` error code. Use **本机听写** in the app. Do not add a model package. This tree does not depend on WhisperKit, llama.cpp, or any other third-party runtime.

### Layout

```
KeyboardApp.xcodeproj/          App + keyboard extension, shared schemes
project.yml                     XcodeGen spec (optional regenerate)
APP_STORE.md                    Bilingual App Store / TestFlight checklist
KeyboardApp/                    SwiftUI onboarding, settings, plist, entitlements
KeyboardExtension/              UIInputViewController, letter rows, voice strip
Packages/KeyboardShared/        Theme, strings, preferences, speech, tone rewrite, tests
```

---

## 中文

### 这一版做什么

- 系统键盘扩展：在其他 App 的输入框里，用地球键可以切到「键盘项目」。
- 主 App 用 SwiftUI 写了三步启用说明、完全访问的「会用到 / 不会做」，以及设置页。
- 键盘是 UIKit：字母行、数字页、大小写、删除、空格、换行、地球键，以及一条语音条。
- **设备端听写**：演示模式关闭、完全访问打开，并且已允许麦克风和语音识别时，使用苹果的 `SFSpeechRecognizer`，并强制 `requiresOnDeviceRecognition`。音频不上传、不保存。该语言不能在本机识别时，听写停止，不会改走服务器。
- **演示模式**默认关闭，仍可在设置里打开。打开后听写只插入内置例句，不建立音频会话。没有完全访问时，键盘读不到设置，使用内置演示。演示模式不改变语气整理。
- **语气整理**：润色、更短、正式（主 App 里还有口语）。键盘优先处理选中文字，否则用刚听写的内容，再否则用光标前一小段。规则在本机执行（苹果平台上的整理步骤会用 `NLTagger` / `NLTokenizer`）。主 App 的试验台在 iOS 26 且 Apple Intelligence 可用时会先试 Foundation Models，失败则回到同一套规则。不做追踪，也不把文字传到自己的服务器。
- 语言偏好只有三种。它决定演示例句、逗号和句号，以及识别语言（`zh-CN`、`en-US`、`ja-JP`）。
- 能配置 App Group 时，设置写在那里。否则只留在当前进程。扩展只有在完全访问打开且 group 可用时才读取共享设置。
- 主 App 里有 **AI 试验台**，不离开 App 就能听写并试四种语气。
- 没有账号、统计、广告或内购。`ProductPolicy` 里这些开关保持关闭。

字母键是占位布局，不是中文、日文或英文输入法。

### 上架路径

[APP_STORE.md](APP_STORE.md) 是中英对照的清单：要替换的 ID、能力、隐私营养标签、截图、可粘贴的审核备注、TestFlight 步骤，以及已知限制。这个仓库不会替你上传构建。

### 和 Sayboard 的关系

[Sayboard](https://github.com/stanlsv/sayboard) 是另一个键盘项目，许可证为 GPL-3。这里只参考它的产品方向，不使用它的源码、资源和许可证文本：

- 能在其他 App 里使用的系统键盘
- 说明如何启用键盘，以及完全访问是什么
- 设备端语音识别
- 在设备上整理听写出来的文字
- 离线取向：没有账号，也不做追踪

没有引入 WhisperKit、llama.cpp 或其他 GPL 运行时，也不提供可选下载。

| | 键盘项目 | Sayboard（只谈产品，不谈源码） |
| --- | --- | --- |
| 许可证 | MIT，不引入 GPL 文件 | GPL-3 |
| 名称和 ID | 键盘项目 / KeyboardApp，`com.mosquito1123.keyboardapp` | 对方自己的名称和标识 |
| 界面 | 暖色主题、自己的文案、字母占位键盘加语音条 | 对方自己的界面 |
| 语音 | 苹果 `SFSpeechRecognizer`，仅设备端，另有演示例句开关 | 对方自己的设备端引擎和模型下载 |
| 润色 | 本机语气（润色、更短、正式、口语）。主 App 在 iOS 26 提供 Foundation Models 时会选用 | 设备端语言模型润色 |
| 语言 | 三种偏好，对应 zh-CN / en-US / ja-JP | 很长的语言列表 |
| 内购和支持邮件 | 没有。追踪和广告也关闭 | 属于那个产品 |
| 代码结构 | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | 对方自己的工程 |

`recognizeOnce()` 和 `complete(prompt:)` 仍然抛出 `notImplemented`。它们是旧入口。键盘走 `SpeechEngines` 和 `RewriteEngines`。

### 仍然存在的限制

- 字母键不是输入法
- 语气整理只会缩短或改写语气，不会编造事实。键盘扩展不链接 Foundation Models
- 没有模型下载页。系统第一次使用某种语言时，可能会自行下载该语言的听写资源
- 即使打开了完全访问，苹果也不保证键盘扩展可以录音。音频会话失败时，语音条会显示错误，输入框不变。请改用主 App 里的「本机听写」
- 没有云端接口，也没有内购
- 只有完全访问打开且 `KEYBOARD_APP_GROUP_ENABLED` 为 YES 时，键盘才能读到主 App 的设置。默认构建不带 App Group，仍然可以在真机运行

不打开 Xcode 也可以检查共享包：

```bash
cd Packages/KeyboardShared
swift test
```

### 环境

- 装有 Xcode 16 或更新版本的 Mac
- iOS 17 模拟器，或 iOS 17 及以上的 iPhone / iPad
- 在 Xcode → Settings → Accounts 里登录 Apple ID

签名、模拟器和「设置」都要在 Mac 上完成。麦克风路径需要真机。模拟器仍可查看界面、演示开关和权限文案。

### 1. 打开工程

```bash
open KeyboardApp.xcodeproj
```

`project.yml` 是 XcodeGen 规格。不安装 XcodeGen 也可以直接打开已生成的工程。改过 `project.yml` 之后再生成：

```bash
brew install xcodegen
xcodegen generate
```

`KeyboardApp/` 和 `KeyboardExtension/` 里新增的 Swift 文件需要加入对应 target。共享包会编译源码目录中的全部文件，包括仅 iOS 会编译的语音文件。

### 2. 选择 Team

1. 选中工程 **KeyboardApp**，再选中 **KeyboardApp** target → **Signing & Capabilities**。
2. 选择你的 **Team**。对 **KeyboardExtension** target 再做一次。
3. 除非这个前缀在你的 Team 上已被占用，否则保持这些 ID：
   - 主 App：`com.mosquito1123.keyboardapp`
   - 键盘：`com.mosquito1123.keyboardapp.keyboard`
   - App Group：`group.com.mosquito1123.keyboardapp`

扩展 ID 仍然是主 App ID 加后缀。同一组字符串写在 `project.yml`、`AppIdentity.swift`、`KeyboardApp/Info.plist` 的 URL name，以及带 App Group 的 entitlements 里。当前工程默认**不签名** App Group，这样真机安装不会因为 group 不可用而失败。下一步和 [APP_STORE.md](APP_STORE.md) 写了怎么打开它。

### 3. App Group（签名）

要让主 App 和键盘共享设置，需要在苹果开发者后台和 Xcode 的 Signing & Capabilities 里，为 `group.com.mosquito1123.keyboardapp` 打开 App Groups。注册 group，加到两个 App ID 上，然后：

1. 把工程构建设置 **`KEYBOARD_APP_GROUP_ENABLED`** 改成 **`YES`**（默认是 `NO`）。这个值会写进两个 Info.plist 的 `KeyboardAppGroupEnabled`。
2. 两个 target 的 **Code Signing Entitlements** 从 `*.NoAppGroup.entitlements` 改成：
   - `KeyboardApp/KeyboardApp.entitlements`
   - `KeyboardExtension/KeyboardExtension.entitlements`

这两个文件里已经是 `group.com.mosquito1123.keyboardapp`。

**免费 Personal Team：** App Groups 经常仍然会被拒绝（`Application Group ... is not available`）。请保持 `KEYBOARD_APP_GROUP_ENABLED` 为 **`NO`**，并继续用 NoAppGroup entitlements。这是默认值，足够在真机运行：

- 主 App 把语言和演示开关写在自己的 `UserDefaults`（仅本进程）。键盘读不到这些值。
- 打开完全访问后，键盘使用自己的默认值（简体中文，演示关闭），仍然可以听写，也可以点润色、更短、正式。
- 没打开完全访问时，键盘继续用内置演示，不打开麦克风。语气按钮仍会整理输入框里已有的文字。
- 主 App 的 AI 试验台不依赖 App Group。

如果即使容器存在也想强制走进程内存储，把 `Packages/KeyboardShared/Package.swift` 里的 `.define("KEYBOARD_APP_GROUP_DISABLED")` 取消注释再编译。`SharedStore.usesAppGroup` 是运行时判断：Info.plist 为 `NO`、定义了该编译旗标，或 `containerURL(forSecurityApplicationGroupIdentifier:)` 为空时，它都是 false。

`RequestsOpenAccess` 不是 entitlement，它在 `KeyboardExtension/Info.plist` 里，并且已经是 `true`。

### 4. 运行

**模拟器**

1. Scheme 选 **KeyboardApp**，目标选任意 iOS 17+ 模拟器。
2. 运行。App 里是启用步骤、设置，以及一个输入框。
3. 设置里可以保持演示关闭，用来看权限说明；也可以打开演示，在不使用麦克风的情况下插入例句。
4. 若只看到硬件键盘：**I/O → Keyboard → Toggle Software Keyboard**（或按 ⌘K）。

**真机**

1. 目标选你的 iPhone 或 iPad。
2. 若系统要求，在设备上打开 **设置 → 隐私与安全性 → 开发者模式**，并信任开发者证书。
3. 运行 **KeyboardApp** scheme，主 App 和内嵌的键盘扩展会一起装上。
4. 在 App 的设置里点 **检查并请求权限**，允许麦克风和语音识别。
5. 演示模式关闭时，在输入框点 **本机听写**，或打开 **AI 试验台** 再听写。**润色 / 更短 / 正式 / 口语** 会在本机整理。键盘上的三个按钮（没有口语）处理选中文字或刚听写的内容。

要调试扩展本身，用 **KeyboardExtension** scheme。Xcode 会询问启动哪个 App。请在「设置」里添加键盘之后，选择 **键盘项目** 或任意带输入框的 App。

### 5. 启用键盘和完全访问

1. **设置 → 通用 → 键盘 → 键盘 → 添加新键盘**。
2. 在第三方键盘里选择 **键盘项目**。
3. 再点一次 **键盘项目**，打开 **允许完全访问**。系统会弹出苹果的标准警告。这一版不会上传按键或音频。演示模式不会录音。设备端听写只在聆听过程中使用麦克风，结束后不保留录音。
4. 点进任意输入框。点地球键，选 **键盘项目**。
5. 在语音条上点麦克风。
   - 演示打开，或完全访问未开：出现例句，标题会标明这是示例。等待过程中再点一次可以取消。
   - 演示关闭且完全访问已开：直接说话。再点一次会结束并插入识别结果，停顿之后也会结束。权限被拒绝、设备端模型不可用、音频会话失败时，输入框都不会被修改，语音条会说明原因。
6. 没有文字时，**润色**、**更短**、**正式** 只显示空状态。有选区时替换选区。否则，若刚听写的文字还在光标前，就替换那一段；再否则替换光标前大约 160 个字。演示模式不会把这些按钮换成带标记的例句。

`RequestsOpenAccess` 为 `true` 时，设置里才会出现「允许完全访问」。开关关闭时，字母键仍然可以打字。在打开之前，语音条会写明自己正在用内置演示，没有读取主 App 的设置。

普通打字不需要网络。这一版不会连接自己的服务器。

### 6. 麦克风

主 App 和扩展的 `NSMicrophoneUsageDescription`、`NSSpeechRecognitionUsageDescription` 都是中英双语。请在主 App 里授权。不要依赖键盘扩展弹出系统权限框。

请在 **真机** 上确认扩展进程能否采集音频。如果不能，语音条会带上 `AVAudioSession` 的错误码。请改用主 App 里的 **本机听写**。不要加入模型包。当前工程不依赖 WhisperKit、llama.cpp 或任何第三方运行时。

### 目录

```
KeyboardApp.xcodeproj/          主 App 与键盘扩展，以及共享的 scheme
project.yml                     XcodeGen 规格（可选，用来重新生成工程）
APP_STORE.md                    中英对照的上架 / TestFlight 清单
KeyboardApp/                    SwiftUI 引导页、设置页、plist、entitlements
KeyboardExtension/              键盘控制器、字母行、语音条
Packages/KeyboardShared/        主题、文案、偏好、语音、语气整理、测试
```

## License

[MIT](LICENSE). This is original work. It is not a GPL fork, and it does not vendor another project’s sources.
