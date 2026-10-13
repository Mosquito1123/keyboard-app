# 键盘项目 / KeyboardApp

Original iOS system keyboard. MIT license. Version **0.2.0**. Deployment target **iOS 17**. Open with **Xcode 16** or newer.

The home-screen name is **键盘项目**. Placeholder bundle IDs:

| Role | Identifier |
| --- | --- |
| Containing app | `com.example.keyboardapp` |
| Keyboard extension | `com.example.keyboardapp.keyboard` |
| App Group | `group.com.example.keyboardapp` |

This repository is not a fork. It does not include code, assets, bundle identifiers, strings, or license text from any other keyboard project.

---

## English

### What this build does

- A system keyboard extension you can switch to from a text field in other apps.
- A SwiftUI app with a three-step enablement guide, a Full Access explanation (what the switch is for, and what this build still does not do), and a Settings screen.
- A UIKit keyboard: QWERTY letter rows, a digit plane, shift, delete, space, return, a globe key, and a voice strip with status text plus a rewrite control.
- `KeyboardShared` protocols for on-device speech and on-device rewriting. **Demo mode** (on by default) waits briefly, then inserts a bundled sample sentence. It does not open an audio session.
- A language preference with three entries. It only changes the sample sentence and the comma / period keys.
- Settings stored in the App Group. The extension reads them only when Allow Full Access is on. Otherwise it keeps a built-in demo (Simplified Chinese, demo on) and says so on the voice strip.

Letter keys are a placeholder layout. They are not a Chinese, Japanese, or English input method.

### Relationship to Sayboard

[Sayboard](https://github.com/stanlsv/sayboard) is a separate, GPL-3 voice keyboard. This project only borrows product ideas from that description:

- a keyboard that works inside other apps
- guidance for turning the keyboard on and for Full Access
- on-device speech recognition as the long-term goal
- on-device rewriting of dictated text as the long-term goal
- an offline posture: no account and no tracking

Intentional differences:

| | KeyboardApp | Sayboard (product, not source) |
| --- | --- | --- |
| License | MIT. No GPL files are vendored. | GPL-3 |
| Name and IDs | 键盘项目 / KeyboardApp, `com.example.keyboardapp` | Their own name and identifiers |
| UI | Warm ink theme, our own copy, a letter-row placeholder plus a voice strip | Their own screens |
| Speech | `SpeechRecognizing`: demo fixture or unwired | On-device engines and model downloads |
| Rewrite | `TextRewriting`: one local tidy-up, about 120 characters before the cursor | On-device language-model rewriting |
| Languages | Three preferences, samples only | A large language list |
| Purchase and support mail | Not included | Part of that product |
| Layout of code | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | Their own project |

Nothing here is a mechanical translation of that repository. `recognizeOnce()` and `complete(prompt:)` still throw `notImplemented`. The demo path is a separate, explicit engine (`SpeechEngines` / `RewriteEngines`) so a sample sentence cannot be mistaken for a real transcript.

### Still stubbed

- No speech engine, no microphone session, no model download
- No language-model runtime
- No cloud API and no in-app purchase
- The language list does not select a recognizer
- Shared settings do not reach the keyboard until Full Access is allowed and the App Group can be provisioned

`Packages/KeyboardShared` can be checked without Xcode:

```bash
cd Packages/KeyboardShared
swift test
```

### Requirements

- A Mac with Xcode 16 or newer
- iOS 17 Simulator, or an iPhone / iPad running iOS 17 or newer
- An Apple ID added in Xcode → Settings → Accounts

Signing, the Simulator, and the Settings app all happen on a Mac.

### 1. Open the project

```bash
open KeyboardApp.xcodeproj
```

`project.yml` is the XcodeGen spec. You do not need XcodeGen to open the checked-in project. After you edit `project.yml`, regenerate with:

```bash
brew install xcodegen
xcodegen generate
```

New Swift files under `KeyboardApp/` and `KeyboardExtension/` are already listed in the checked-in project. The shared package compiles every file in its source directory.

### 2. Set the team and replace the placeholder IDs

1. Select the **KeyboardApp** project, then the **KeyboardApp** target → **Signing & Capabilities**.
2. Choose your **Team**. Repeat for the **KeyboardExtension** target.
3. Replace `com.example.keyboardapp` and `com.example.keyboardapp.keyboard` with IDs you own. Change them in:
   - `project.yml` (then run `xcodegen generate`), or the same `PRODUCT_BUNDLE_IDENTIFIER` settings in the target build settings
   - `Packages/KeyboardShared/Sources/KeyboardShared/AppIdentity.swift` (the onboarding screen reads this)
   - both `*.entitlements` files (`group.com.example...`)
   - `KeyboardApp/Info.plist` URL name, if you keep the reserved `keyboardapp://` scheme

The extension ID must stay a child of the app ID (prefix plus a suffix such as `.keyboard`).

### 3. App Group (signing)

Both targets include the App Group `group.com.example.keyboardapp`. Settings writes go there. The keyboard reads them only when Full Access is on.

- **Paid Apple Developer Program:** register the group for your team and use the same string in both entitlements.
- **Free Personal Team:** App Groups are often unavailable. If signing fails with a provisioning error about application groups, delete the `com.apple.security.application-groups` key from **both** entitlements files, then try again. The keyboard will keep using its built-in demo until the group exists. Put the key back when you have a team that can create it.

`RequestsOpenAccess` is not an entitlement. It lives in `KeyboardExtension/Info.plist` and is already `true`.

### 4. Run

**Simulator**

1. Scheme **KeyboardApp**, destination any iOS 17+ simulator.
2. Run. The app shows the enablement steps, Settings, and a text field.
3. In the text field, tap **插入语音示例** or **润色这段文字**. After a short pause the field changes. Turn demo mode off in Settings and the same buttons only explain that demo mode is off.
4. If the software keyboard is hidden: **I/O → Keyboard → Toggle Software Keyboard** (or press ⌘K).

**Device**

1. Destination: your iPhone or iPad.
2. On the device, turn on **Settings → Privacy & Security → Developer Mode** if iOS asks, then trust the developer certificate.
3. Run the **KeyboardApp** scheme so the app and the embedded extension install together.

To debug the extension itself, use the **KeyboardExtension** scheme. Xcode asks which app to launch. Pick **键盘项目** or any app with a text field, after the keyboard has been added in Settings.

### 5. Enable the keyboard and Full Access

1. **Settings → General → Keyboard → Keyboards → Add New Keyboard**.
2. Under third-party keyboards, choose **键盘项目**.
3. Tap **键盘项目** again and turn on **Allow Full Access**. iOS shows Apple’s standard warning. This build still does not upload keystrokes or audio, and demo mode does not record.
4. Focus a text field. Tap the globe key and select **键盘项目**.
5. On the voice strip, tap the microphone. With demo mode on, a sample sentence appears after a short wait. Tap again during the wait to cancel. **润色** replaces up to about 120 characters before the cursor with a labeled local tidy-up, when that suffix is still in place.

`RequestsOpenAccess` is `true`, which is what makes the Allow Full Access switch appear. Letter keys still type when the switch is off. Until it is on, the voice strip says it is using the built-in demo and is not reading the app’s settings.

Basic typing does not need the network. This build does not contact a server.

### 6. Microphone, and what you must verify later

Apple does not publicly guarantee that a custom keyboard extension can record, even after Allow Full Access is on. `NSMicrophoneUsageDescription` is present on the app and the extension so a future call does not crash for a missing purpose string. This build never triggers the microphone prompt.

Before replacing `UnwiredSpeechRecognizer`, confirm on a **device** (not only the Simulator) whether the extension process can capture audio. If it cannot, record in the containing app and pass text back through the App Group. The reserved URL scheme `keyboardapp://` is unused. Do not add a model package unless it is optional, clearly gated, and compatible with the MIT license. This tree does not depend on one.

### Layout

```
KeyboardApp.xcodeproj/          App + keyboard extension, shared schemes
project.yml                     XcodeGen spec (optional regenerate)
KeyboardApp/                    SwiftUI onboarding, settings, plist, entitlements
KeyboardExtension/              UIInputViewController, letter rows, voice strip
Packages/KeyboardShared/        Theme, strings, preferences, speech and rewrite stubs, tests
```

---

## 中文

### 这一版做什么

- 系统键盘扩展：在其他 App 的输入框里，用地球键可以切到「键盘项目」。
- 主 App 用 SwiftUI 写了三步启用说明、完全访问的「会用到 / 不会做」，以及设置页。
- 键盘是 UIKit：字母行、数字页、大小写、删除、空格、换行、地球键，以及一条带状态文字的语音条和「润色」按钮。
- `KeyboardShared` 里是端侧语音和端侧润色的协议。**演示模式**默认打开：停顿一下，再插入写在 App 里的例句。它不会建立音频会话。
- 语言偏好只有三种，只改变例句以及逗号、句号。
- 设置写在 App Group。扩展只有在「允许完全访问」打开后才读取。否则使用内置演示（简体中文、演示开），语音条会说明这一点。

字母键是占位布局，不是中文、日文或英文输入法。

### 和 Sayboard 的关系

[Sayboard](https://github.com/stanlsv/sayboard) 是另一个键盘项目，许可证为 GPL-3。这里只参考它的产品方向，不使用它的源码：

- 能在其他 App 里使用的系统键盘
- 说明如何启用键盘，以及完全访问是什么
- 长期目标是设备端语音识别
- 长期目标是在设备上整理听写出来的文字
- 离线取向：没有账号，也不做追踪

有意保持的差别：

| | 键盘项目 | Sayboard（只谈产品，不谈源码） |
| --- | --- | --- |
| 许可证 | MIT，不引入 GPL 文件 | GPL-3 |
| 名称和 ID | 键盘项目 / KeyboardApp，`com.example.keyboardapp` | 对方自己的名称和标识 |
| 界面 | 暖色主题、自己的文案、字母占位键盘加语音条 | 对方自己的界面 |
| 语音 | `SpeechRecognizing`：演示样本或未接入 | 设备端引擎和模型下载 |
| 润色 | `TextRewriting`：一次本地整理，大约光标前 120 字 | 设备端语言模型润色 |
| 语言 | 三种偏好，只影响示例 | 很长的语言列表 |
| 内购和支持邮件 | 没有 | 属于那个产品 |
| 代码结构 | `KeyboardApp` + `KeyboardExtension` + `KeyboardShared` | 对方自己的工程 |

这里没有搬运或逐行改写那个仓库。`recognizeOnce()` 和 `complete(prompt:)` 仍然抛出 `notImplemented`。演示走单独的 `SpeechEngines` / `RewriteEngines`，避免把例句当成真实识别结果。

### 仍是占位

- 没有识别引擎，没有麦克风会话，没有模型下载
- 没有语言模型运行时
- 没有云端接口，也没有内购
- 语言列表不会切换识别器
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

签名、模拟器和「设置」都要在 Mac 上完成。

### 1. 打开工程

```bash
open KeyboardApp.xcodeproj
```

`project.yml` 是 XcodeGen 规格。不安装 XcodeGen 也可以直接打开已生成的工程。改过 `project.yml` 之后再生成：

```bash
brew install xcodegen
xcodegen generate
```

`KeyboardApp/` 和 `KeyboardExtension/` 里的新 Swift 文件已经写进现有工程。共享包会编译源码目录中的全部文件。

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

两个 target 都带了 App Group `group.com.example.keyboardapp`。设置会写到这里。键盘只在完全访问打开后读取。

- **付费开发者计划：** 为你的 Team 注册这个 group，两个 entitlements 使用同一字符串。
- **免费 Personal Team：** 通常不能使用 App Group。如果签名报错提到 application groups，把两个 entitlements 里的 `com.apple.security.application-groups` 删掉再试。在 group 可用之前，键盘会一直用内置演示。以后有可用的 Team 时再把这项加回来。

`RequestsOpenAccess` 不是 entitlement，它在 `KeyboardExtension/Info.plist` 里，并且已经是 `true`。

### 4. 运行

**模拟器**

1. Scheme 选 **KeyboardApp**，目标选任意 iOS 17+ 模拟器。
2. 运行。App 里是启用步骤、设置，以及一个输入框。
3. 在输入框旁点 **插入语音示例** 或 **润色这段文字**。停顿之后文字会变化。到设置里关掉演示模式，同样的按钮只会说明演示已关闭。
4. 若只看到硬件键盘：**I/O → Keyboard → Toggle Software Keyboard**（或按 ⌘K）。

**真机**

1. 目标选你的 iPhone 或 iPad。
2. 若系统要求，在设备上打开 **设置 → 隐私与安全性 → 开发者模式**，并信任开发者证书。
3. 运行 **KeyboardApp** scheme，主 App 和内嵌的键盘扩展会一起装上。

要调试扩展本身，用 **KeyboardExtension** scheme。Xcode 会询问启动哪个 App。请在「设置」里添加键盘之后，选择 **键盘项目** 或任意带输入框的 App。

### 5. 启用键盘和完全访问

1. **设置 → 通用 → 键盘 → 键盘 → 添加新键盘**。
2. 在第三方键盘里选择 **键盘项目**。
3. 再点一次 **键盘项目**，打开 **允许完全访问**。系统会弹出苹果的标准警告。这一版仍然不会上传按键或音频，演示模式也不会录音。
4. 点进任意输入框。点地球键，选 **键盘项目**。
5. 在语音条上点麦克风。演示模式打开时，稍等就会出现例句。等待过程中再点一次可以取消。**润色** 会在光标前大约 120 个字仍然原样留着时，把它们换成带标记的本地整理结果。

`RequestsOpenAccess` 为 `true` 时，设置里才会出现「允许完全访问」。开关关闭时，字母键仍然可以打字。在打开之前，语音条会写明自己正在用内置演示，没有读取主 App 的设置。

普通打字不需要网络。这一版不会连接服务器。

### 6. 麦克风，以及以后必须在真机上确认的事

即使打开了完全访问，苹果也没有公开保证自定义键盘扩展可以录音。主 App 和扩展的 `NSMicrophoneUsageDescription` 只是预留说明，避免以后调用麦克风时因为缺少用途字符串而崩溃。当前版本不会弹出麦克风权限。

替换 `UnwiredSpeechRecognizer` 之前，请在 **真机**（不要只看模拟器）上确认扩展进程能否采集音频。如果不能，应改由主 App 录音，再通过 App Group 把文本交回键盘。预留的 URL scheme `keyboardapp://` 目前没有被调用。除非某个模型包是可选的、有明确开关，并且和 MIT 许可证兼容，否则不要加进来。当前工程不依赖这类包。

### 目录

```
KeyboardApp.xcodeproj/          主 App 与键盘扩展，以及共享的 scheme
project.yml                     XcodeGen 规格（可选，用来重新生成工程）
KeyboardApp/                    SwiftUI 引导页、设置页、plist、entitlements
KeyboardExtension/              键盘控制器、字母行、语音条
Packages/KeyboardShared/        主题、文案、偏好、语音和润色占位、测试
```

## License

[MIT](LICENSE). This is original work. It is not a GPL fork, and it does not vendor another project’s sources.
