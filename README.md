# 键盘项目 / KeyboardApp

Original iOS system keyboard. MIT license. Version **0.3.0**. Deployment target **iOS 17**. Open with **Xcode 16** or newer.

The home-screen name is **键盘项目**. Placeholder bundle IDs (replace them before TestFlight or the App Store; the checklist is [APP_STORE.md](APP_STORE.md)):

| Role | Identifier |
| --- | --- |
| Containing app | `com.example.keyboardapp` |
| Keyboard extension | `com.example.keyboardapp.keyboard` |
| App Group | `group.com.example.keyboardapp` |

This repository is not a fork. It does not include code, assets, bundle identifiers, strings, or license text from any other keyboard project.

Shared schemes **KeyboardApp** and **KeyboardExtension** are in `KeyboardApp.xcodeproj`. Archive the **KeyboardApp** scheme. It embeds the extension.

---

## English

### What this build does

- A system keyboard extension you can switch to from a text field in other apps.
- A SwiftUI app with a three-step enablement guide, a Full Access explanation, and Settings.
- A UIKit keyboard: QWERTY letter rows, a digit plane, shift, delete, space, return, a globe key, and a voice strip.
- **On-device dictation** when demo mode is off, Full Access is on, and microphone plus speech recognition are allowed. The recognizer is Apple's `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`. Audio is not uploaded and not stored. If on-device recognition is unavailable, dictation stops. It does not call a server.
- **Demo mode** (off by default, still in Settings) inserts a bundled sample sentence and does not open an audio session. Without Full Access the keyboard cannot read Settings and uses that built-in demo.
- **Rewrite** tidies about 120 characters before the cursor: spacing, English sentence case, and a closing mark. On Apple platforms the pass uses `NLTagger` / `NLTokenizer`. It is not a language model. An empty field shows an empty state and inserts nothing. Demo mode still inserts a labeled sample instead.
- A language preference with three entries. It selects the demo sentence, the comma and period keys, and the speech locale (`zh-CN`, `en-US`, `ja-JP`).
- Settings stored in the App Group. The extension reads them only when Allow Full Access is on.
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
| Name and IDs | 键盘项目 / KeyboardApp, `com.example.keyboardapp` | Their own name and identifiers |
| UI | Warm ink theme, our own copy, a letter-row placeholder plus a voice strip | Their own screens |
| Speech | Apple `SFSpeechRecognizer`, on-device only, plus a demo-sample toggle | Their own on-device engines and model downloads |
| Rewrite | Local tidy-up (`NLTagger` or the same heuristics), about 120 characters. Demo mode labels a sample. | On-device language-model rewriting |
| Languages | Three preferences, mapped to zh-CN / en-US / ja-JP | A large language list |
| Purchase and support mail | Not included. Tracking and ads are off. | Part of that product |
| Layout of code | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | Their own project |

`recognizeOnce()` and `complete(prompt:)` still throw `notImplemented`. They are legacy entry points. The keyboard calls `SpeechEngines` and `RewriteEngines`.

### Limits that are still real

- The letter layout is not an input method
- Rewrite does not generate new sentences
- No model-download screen. iOS may download its own dictation assets the first time a language is used
- Apple does not guarantee that a keyboard extension can record, even with Full Access. If the audio session fails, the voice strip shows the error and the field is unchanged. Dictate from the containing app instead
- No cloud API and no in-app purchase
- Shared settings do not reach the keyboard until Full Access is on and the App Group can be provisioned

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

### 2. Set the team and replace the placeholder IDs

1. Select the **KeyboardApp** project, then the **KeyboardApp** target → **Signing & Capabilities**.
2. Choose your **Team**. Repeat for the **KeyboardExtension** target.
3. Replace `com.example.keyboardapp` and `com.example.keyboardapp.keyboard` with IDs you own. Change them in:
   - `project.yml` (then run `xcodegen generate`), or the same `PRODUCT_BUNDLE_IDENTIFIER` settings in the target build settings
   - `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift` (the onboarding screen reads this)
   - both `*.entitlements` files (`group.com.example...`)
   - `KeyboardApp/Info.plist` URL name, if you keep the reserved `keyboardapp://` scheme

The extension ID must stay a child of the app ID (prefix plus a suffix such as `.keyboard`). The full list is in [APP_STORE.md](APP_STORE.md).

### 3. App Group (signing)

Both targets include the App Group `group.com.example.keyboardapp`. Settings writes go there. The keyboard reads them only when Full Access is on.

- **Paid Apple Developer Program:** register the group for your team and use the same string in both entitlements.
- **Free Personal Team:** App Groups are often unavailable. If signing fails with a provisioning error about application groups, delete the `com.apple.security.application-groups` key from **both** entitlements files, then try again. The keyboard will keep using its built-in demo until the group exists. Put the key back when you have a team that can create it.

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
5. With demo mode off, tap **本机听写** in the text field. The system recording indicator should appear, and the transcript should be inserted. **润色** tidies that text on device.

To debug the extension itself, use the **KeyboardExtension** scheme. Xcode asks which app to launch. Pick **键盘项目** or any app with a text field, after the keyboard has been added in Settings.

### 5. Enable the keyboard and Full Access

1. **Settings → General → Keyboard → Keyboards → Add New Keyboard**.
2. Under third-party keyboards, choose **键盘项目**.
3. Tap **键盘项目** again and turn on **Allow Full Access**. iOS shows Apple’s standard warning. This build does not upload keystrokes or audio. Demo mode does not record. On-device dictation records only while you are listening, then discards the audio.
4. Focus a text field. Tap the globe key and select **键盘项目**.
5. On the voice strip, tap the microphone.
   - Demo on, or Full Access off: a sample sentence appears. The title says it is a sample. Tap again during the wait to cancel.
   - Demo off and Full Access on: speak. A second tap ends listening and inserts the transcript. A pause does the same. Permission problems, an unavailable on-device model, and an audio-session failure each leave the field unchanged and explain why.
6. **润色** with an empty field shows an empty state. With text, it replaces up to about 120 characters before the cursor when that suffix is still in place.

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
Packages/KeyboardShared/        Theme, strings, preferences, speech, tidy-up, tests
```

---

## 中文

### 这一版做什么

- 系统键盘扩展：在其他 App 的输入框里，用地球键可以切到「键盘项目」。
- 主 App 用 SwiftUI 写了三步启用说明、完全访问的「会用到 / 不会做」，以及设置页。
- 键盘是 UIKit：字母行、数字页、大小写、删除、空格、换行、地球键，以及一条语音条。
- **设备端听写**：演示模式关闭、完全访问打开，并且已允许麦克风和语音识别时，使用苹果的 `SFSpeechRecognizer`，并强制 `requiresOnDeviceRecognition`。音频不上传、不保存。该语言不能在本机识别时，听写停止，不会改走服务器。
- **演示模式**默认关闭，仍可在设置里打开。打开后只插入内置例句，不建立音频会话。没有完全访问时，键盘读不到设置，使用内置演示。
- **润色**整理光标前大约 120 个字：空白、英文句首大小写、句末标点。在苹果平台上会用到 `NLTagger` / `NLTokenizer`。这不是语言模型。没有文字时只显示空状态，不插入内容。演示模式仍会插入带标记的例句。
- 语言偏好只有三种。它决定演示例句、逗号和句号，以及识别语言（`zh-CN`、`en-US`、`ja-JP`）。
- 设置写在 App Group。扩展只有在「允许完全访问」打开后才读取。
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
| 名称和 ID | 键盘项目 / KeyboardApp，`com.example.keyboardapp` | 对方自己的名称和标识 |
| 界面 | 暖色主题、自己的文案、字母占位键盘加语音条 | 对方自己的界面 |
| 语音 | 苹果 `SFSpeechRecognizer`，仅设备端，另有演示例句开关 | 对方自己的设备端引擎和模型下载 |
| 润色 | 本地整理（`NLTagger` 或同一套规则），大约光标前 120 字。演示模式会插入带标记的例句 | 设备端语言模型润色 |
| 语言 | 三种偏好，对应 zh-CN / en-US / ja-JP | 很长的语言列表 |
| 内购和支持邮件 | 没有。追踪和广告也关闭 | 属于那个产品 |
| 代码结构 | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | 对方自己的工程 |

`recognizeOnce()` 和 `complete(prompt:)` 仍然抛出 `notImplemented`。它们是旧入口。键盘走 `SpeechEngines` 和 `RewriteEngines`。

### 仍然存在的限制

- 字母键不是输入法
- 润色不会生成新句子
- 没有模型下载页。系统第一次使用某种语言时，可能会自行下载该语言的听写资源
- 即使打开了完全访问，苹果也不保证键盘扩展可以录音。音频会话失败时，语音条会显示错误，输入框不变。请改用主 App 里的「本机听写」
- 没有云端接口，也没有内购
- 在完全访问打开、并且 App Group 能够配置之前，键盘读不到主 App 里的设置

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

### 2. 选择 Team，并换掉占位 ID

1. 选中工程 **KeyboardApp**，再选中 **KeyboardApp** target → **Signing & Capabilities**。
2. 选择你的 **Team**。对 **KeyboardExtension** target 再做一次。
3. 把 `com.example.keyboardapp` 和 `com.example.keyboardapp.keyboard` 换成你拥有的 ID。需要一起改的位置：
   - `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER`（然后执行 `xcodegen generate`），或 target 构建设置里的同一项
   - `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift`（引导页会读这里）
   - 两个 `*.entitlements` 里的 `group.com.example...`
   - 如果保留预留的 `keyboardapp://`，还有 `KeyboardApp/Info.plist` 里的 URL name

扩展的 Bundle ID 必须是主 App ID 加上后缀（例如 `.keyboard`）。完整列表在 [APP_STORE.md](APP_STORE.md)。

### 3. App Group（签名）

两个 target 都带了 App Group `group.com.example.keyboardapp`。设置会写到这里。键盘只在完全访问打开后读取。

- **付费开发者计划：** 为你的 Team 注册这个 group，两个 entitlements 使用同一字符串。
- **免费 Personal Team：** 通常不能使用 App Group。如果签名报错提到 application groups，把两个 entitlements 里的 `com.apple.security.application-groups` 删掉再试。在 group 可用之前，键盘会一直用内置演示。以后有可用的 Team 时再把这项加回来。

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
5. 演示模式关闭时，在输入框点 **本机听写**。系统会出现录音指示，识别结果会插入输入框。**润色** 在本机整理这段文字。

要调试扩展本身，用 **KeyboardExtension** scheme。Xcode 会询问启动哪个 App。请在「设置」里添加键盘之后，选择 **键盘项目** 或任意带输入框的 App。

### 5. 启用键盘和完全访问

1. **设置 → 通用 → 键盘 → 键盘 → 添加新键盘**。
2. 在第三方键盘里选择 **键盘项目**。
3. 再点一次 **键盘项目**，打开 **允许完全访问**。系统会弹出苹果的标准警告。这一版不会上传按键或音频。演示模式不会录音。设备端听写只在聆听过程中使用麦克风，结束后不保留录音。
4. 点进任意输入框。点地球键，选 **键盘项目**。
5. 在语音条上点麦克风。
   - 演示打开，或完全访问未开：出现例句，标题会标明这是示例。等待过程中再点一次可以取消。
   - 演示关闭且完全访问已开：直接说话。再点一次会结束并插入识别结果，停顿之后也会结束。权限被拒绝、设备端模型不可用、音频会话失败时，输入框都不会被修改，语音条会说明原因。
6. 光标前没有文字时，**润色** 只显示空状态。有文字时，会在那一小段仍然留在光标前的情况下，替换大约 120 个字。

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
Packages/KeyboardShared/        主题、文案、偏好、语音、整理、测试
```

## License

[MIT](LICENSE). This is original work. It is not a GPL fork, and it does not vendor another project’s sources.
