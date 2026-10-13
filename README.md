# 键盘项目 / KeyboardApp

Original iOS system-keyboard skeleton. MIT license. This repository is not a fork and does not include code, assets, or bundle identifiers from any other keyboard project.

Deployment target: **iOS 17**. Open with **Xcode 16** or newer.

The home-screen name is **键盘项目**. Placeholder bundle IDs:

| Role | Identifier |
| --- | --- |
| Containing app | `com.example.keyboardapp` |
| Keyboard extension | `com.example.keyboardapp.keyboard` |
| App Group | `group.com.example.keyboardapp` |

---

## English

### What this build does

- A SwiftUI app that explains how to turn the keyboard on in Settings.
- A Custom Keyboard extension with a few placeholder keys (they insert text), delete, return, a globe key, and a microphone button.
- A local Swift package, `KeyboardShared`, for colors, copy, and the speech / language-model stubs.

The microphone button only shows a status line. It does not open an audio session and does not run recognition.

### Requirements

- A Mac with Xcode 16 or newer
- iOS 17 Simulator, or an iPhone / iPad running iOS 17 or newer
- An Apple ID added in Xcode → Settings → Accounts

This tree cannot be compiled on Linux. Signing, the Simulator, and Settings all happen on your Mac.

### 1. Open the project

Unzip `KeyboardApp-skeleton.zip` into Downloads, then:

```bash
cd ~/Downloads/KeyboardApp
open KeyboardApp.xcodeproj
```

`project.yml` is the XcodeGen spec. You do not need XcodeGen to open the checked-in project. After you edit `project.yml`, regenerate with:

```bash
brew install xcodegen
xcodegen generate
```

### 2. Set the team and replace the placeholder IDs

1. Select the **KeyboardApp** project, then the **KeyboardApp** target → **Signing & Capabilities**.
2. Choose your **Team**. Repeat for the **KeyboardExtension** target.
3. Replace `com.example.keyboardapp` and `com.example.keyboardapp.keyboard` with IDs you own. Change them in:
   - `project.yml` (then run `xcodegen generate`), or the same `PRODUCT_BUNDLE_IDENTIFIER` settings in the target build settings
   - `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift` (so the onboarding screen matches)
   - both `*.entitlements` files (`group.com.example...`)
   - `KeyboardApp/Info.plist` URL name, if you keep the reserved `keyboardapp://` scheme

The extension ID must stay a child of the app ID (prefix plus a suffix such as `.keyboard`).

### 3. App Group (signing)

Both targets include the App Group `group.com.example.keyboardapp`. The skeleton never reads or writes that container. It is there so a later build can share settings or a transcript.

- **Paid Apple Developer Program:** register the group for your team (developer portal, or the capability editor in Xcode) and use the same string in both entitlements.
- **Free Personal Team:** App Groups are often unavailable. If signing fails with a provisioning error about application groups, delete the `com.apple.security.application-groups` key from **both** entitlements files, then try again. Put the key back when you have a team that can create the group.

`RequestsOpenAccess` is not an entitlement. It lives in `KeyboardExtension/Info.plist` and is already `true`.

### 4. Run

**Simulator**

1. Scheme **KeyboardApp**, destination any iOS 17+ simulator.
2. Run. The app shows the enablement steps and a text field.
3. If the software keyboard is hidden: **I/O → Keyboard → Toggle Software Keyboard** (or press ⌘K).

**Device**

1. Destination: your iPhone or iPad.
2. On the device, turn on **Settings → Privacy & Security → Developer Mode** if iOS asks, then trust the developer certificate.
3. Run the **KeyboardApp** scheme so the app and the embedded extension install together.

To debug the extension itself, use the **KeyboardExtension** scheme. Xcode asks which app to launch. Pick **键盘项目** or any app with a text field, after the keyboard has been added in Settings.

### 5. Enable the keyboard and Full Access

1. **Settings → General → Keyboard → Keyboards → Add New Keyboard**.
2. Under third-party keyboards, choose **键盘项目**.
3. Tap **键盘项目** again and turn on **Allow Full Access** (允许完全访问). iOS shows Apple’s standard warning. This build still does not upload keystrokes or audio.
4. Focus a text field (the one in the app is enough). Tap the globe key and select **键盘项目**.

`RequestsOpenAccess` is `true`, which is what makes the Allow Full Access switch appear. Placeholder keys still type when the switch is off. The status line on the microphone key reports whether Full Access is on.

Basic typing does not need the network. This build does not contact a server.

### 6. Microphone, and what you must verify later

Apple does not publicly guarantee that a custom keyboard extension can record, even after Allow Full Access is on. `NSMicrophoneUsageDescription` is present on the app and the extension so a future call does not crash for a missing purpose string. This skeleton never triggers the microphone prompt.

Before replacing `SpeechRecognizerStub`, confirm on a **device** (not only the Simulator) whether the extension process can capture audio. If it cannot, record in the containing app and pass text back through the App Group. The reserved URL scheme `keyboardapp://` is unused.

### Out of scope

- WhisperKit or any speech-recognition model
- An on-device large language model
- App Store in-app purchase
- Cloud APIs that need a key

`SpeechRecognizerStub.recognizeOnce()` and `LanguageModelStub.complete(prompt:)` throw `notImplemented`. The microphone button does not call them.

### Layout

```
KeyboardApp.xcodeproj/          App + keyboard extension, shared schemes
project.yml                     XcodeGen spec (optional regenerate)
KeyboardApp/                    SwiftUI onboarding, plist, entitlements
KeyboardExtension/              UIInputViewController, placeholder keys, mic button
Packages/KeyboardShared/        Theme, strings, speech stub, language-model stub
```

---

## 中文

### 这一版做什么

- 主 App 用 SwiftUI 说明如何在「设置」里启用键盘。
- 键盘扩展是系统级自定义键盘：几个占位键会插入文字，另外有删除、换行、地球键和麦克风按钮。
- 本地 Swift 包 `KeyboardShared` 放颜色、文案，以及语音 / 语言模型的空实现。

麦克风按钮只显示状态。它不会建立音频会话，也不会开始识别。

### 环境

- 装有 Xcode 16 或更新版本的 Mac
- iOS 17 模拟器，或 iOS 17 及以上的 iPhone / iPad
- 在 Xcode → Settings → Accounts 里登录 Apple ID

这份工程不能在 Linux 上编译。签名、模拟器和「设置」都要在 Mac 上完成。

### 1. 打开工程

把 `KeyboardApp-skeleton.zip` 解压到「下载」，然后：

```bash
cd ~/Downloads/KeyboardApp
open KeyboardApp.xcodeproj
```

`project.yml` 是 XcodeGen 规格。不安装 XcodeGen 也可以直接打开已生成的工程。改过 `project.yml` 之后再生成：

```bash
brew install xcodegen
xcodegen generate
```

### 2. 选择 Team，并换掉占位 ID

1. 选中工程 **KeyboardApp**，再选中 **KeyboardApp** target → **Signing & Capabilities**。
2. 选择你的 **Team**。对 **KeyboardExtension** target 再做一次。
3. 把 `com.example.keyboardapp` 和 `com.example.keyboardapp.keyboard` 换成你拥有的 ID。需要一起改的位置：
   - `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER`（然后执行 `xcodegen generate`），或 target 构建设置里的同一项
   - `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift`（引导页会读这里）
   - 两个 `*.entitlements` 里的 `group.com.example...`
   - 如果保留预留的 `keyboardapp://`，还有 `KeyboardApp/Info.plist` 里的 URL name

扩展的 Bundle ID 必须是主 App ID 加上后缀（例如 `.keyboard`）。

### 3. App Group（签名）

两个 target 都带了 App Group `group.com.example.keyboardapp`。当前骨架不会读写这个容器，只为以后共享设置或识别文本预留。

- **付费开发者计划：** 在开发者网站或 Xcode 的能力编辑器里为你的 Team 注册这个 group，两个 entitlements 使用同一字符串。
- **免费 Personal Team：** 通常不能使用 App Group。如果签名报错提到 application groups，把两个 entitlements 里的 `com.apple.security.application-groups` 删掉再试。以后有可用的 Team 时再加回来。

`RequestsOpenAccess` 不是 entitlement，它在 `KeyboardExtension/Info.plist` 里，并且已经是 `true`。

### 4. 运行

**模拟器**

1. Scheme 选 **KeyboardApp**，目标选任意 iOS 17+ 模拟器。
2. 运行。App 里是启用步骤和一个输入框。
3. 若只看到硬件键盘：**I/O → Keyboard → Toggle Software Keyboard**（或按 ⌘K）。

**真机**

1. 目标选你的 iPhone 或 iPad。
2. 若系统要求，在设备上打开 **设置 → 隐私与安全性 → 开发者模式**，并信任开发者证书。
3. 运行 **KeyboardApp** scheme，主 App 和内嵌的键盘扩展会一起装上。

要调试扩展本身，用 **KeyboardExtension** scheme。Xcode 会询问启动哪个 App。请在「设置」里添加键盘之后，选择 **键盘项目** 或任意带输入框的 App。

### 5. 启用键盘和完全访问

1. **设置 → 通用 → 键盘 → 键盘 → 添加新键盘**。
2. 在第三方键盘里选择 **键盘项目**。
3. 再点一次 **键盘项目**，打开 **允许完全访问**。系统会弹出苹果的标准警告。这一版仍然不会上传按键或音频。
4. 点进任意输入框（用 App 里的输入框即可）。点地球键，选 **键盘项目**。

`RequestsOpenAccess` 为 `true` 时，设置里才会出现「允许完全访问」。开关关闭时，占位键仍然可以打字。麦克风键上的状态行会显示完全访问是否已打开。

普通打字不需要网络。这一版不会连接服务器。

### 6. 麦克风，以及以后必须在真机上确认的事

即使打开了完全访问，苹果也没有公开保证自定义键盘扩展可以录音。主 App 和扩展的 `NSMicrophoneUsageDescription` 只是预留说明，避免以后调用麦克风时因为缺少用途字符串而崩溃。当前骨架不会弹出麦克风权限。

替换 `SpeechRecognizerStub` 之前，请在 **真机**（不要只看模拟器）上确认扩展进程能否采集音频。如果不能，应改由主 App 录音，再通过 App Group 把文本交回键盘。预留的 URL scheme `keyboardapp://` 目前没有被调用。

### 故意没做

- WhisperKit 或任何语音识别模型
- 端侧大语言模型
- App Store 内购
- 需要密钥的云端接口

`SpeechRecognizerStub.recognizeOnce()` 和 `LanguageModelStub.complete(prompt:)` 会抛出 `notImplemented`。麦克风按钮不会调用它们。

### 目录

```
KeyboardApp.xcodeproj/          主 App 与键盘扩展，以及共享的 scheme
project.yml                     XcodeGen 规格（可选，用来重新生成工程）
KeyboardApp/                    SwiftUI 引导页、plist、entitlements
KeyboardExtension/              键盘控制器、占位键、麦克风按钮
Packages/KeyboardShared/        主题、文案、语音空实现、语言模型空实现
```

## License

[MIT](LICENSE). This is original work. It is not a GPL fork, and it does not vendor another project’s sources.
