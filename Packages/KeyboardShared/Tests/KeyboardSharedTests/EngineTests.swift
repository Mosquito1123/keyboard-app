import XCTest
@testable import KeyboardShared

private final class FinishFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var marked = false

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return marked
    }

    func mark() {
        lock.lock()
        marked = true
        lock.unlock()
    }
}

final class EngineTests: XCTestCase {
    func testDemoSpeechInsertsLanguageSample() async throws {
        let engine = DemoSpeechRecognizer(delayNanoseconds: 1_000_000)
        let utterance = try await engine.transcribe(language: .english)
        XCTAssertEqual(utterance.text, TypingLanguage.english.sampleUtterance)
        XCTAssertTrue(utterance.usedDemoFixture)
        XCTAssertEqual(utterance.engineName, "demo-fixture")
    }

    func testUnwiredSpeechDoesNotReturnText() async {
        let engine = UnwiredSpeechRecognizer()
        do {
            _ = try await engine.transcribe(language: .simplifiedChinese)
            XCTFail("Expected notImplemented")
        } catch let error as SpeechStubError {
            XCTAssertEqual(error, .notImplemented)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testLegacyRecognizeOnceStaysUnwired() async {
        do {
            _ = try await SpeechRecognizerStub().recognizeOnce()
            XCTFail("Expected notImplemented")
        } catch let error as SpeechStubError {
            XCTAssertEqual(error, .notImplemented)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testDemoSpeechCanBeCancelled() async {
        let engine = DemoSpeechRecognizer(delayNanoseconds: 2_000_000_000)
        let task = Task {
            try await engine.transcribe(language: .japanese)
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testDemoRewriteLabelsEmptyAndExistingText() async throws {
        let engine = DemoTextRewriter(delayNanoseconds: 1_000_000)
        let empty = try await engine.rewrite("   ", language: .simplifiedChinese)
        XCTAssertEqual(empty.text, TypingLanguage.simplifiedChinese.demoRewrite(of: ""))
        XCTAssertTrue(empty.text.contains("演示润色"))

        let rewritten = try await engine.rewrite("  下午见  ", language: .english)
        XCTAssertEqual(rewritten.text, "(demo rewrite) 下午见.")
        XCTAssertTrue(rewritten.usedDemoFixture)
    }

    func testUnwiredRewriteAndCompleteStayUnwired() async {
        do {
            _ = try await UnwiredTextRewriter().rewrite("hello", language: .english)
            XCTFail("Expected notImplemented")
        } catch let error as LanguageModelStubError {
            XCTAssertEqual(error, .notImplemented)
        } catch {
            XCTFail("Unexpected error \(error)")
        }

        do {
            _ = try await LanguageModelStub().complete(prompt: "hello")
            XCTFail("Expected notImplemented")
        } catch let error as LanguageModelStubError {
            XCTAssertEqual(error, .notImplemented)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testEnginesFollowDemoFlag() async throws {
        let demo = SpeechEngines.make(demoMode: true, delayNanoseconds: 1_000_000)
        let utterance = try await demo.transcribe(language: .japanese)
        XCTAssertEqual(utterance.text, TypingLanguage.japanese.sampleUtterance)
        XCTAssertTrue(utterance.usedDemoFixture)

        let rewrite = RewriteEngines.make(demoMode: false)
        let passage = try await rewrite.rewrite("  hello   world ", language: .english)
        XCTAssertEqual(passage.engineName, "on-device-tidy")
        XCTAssertFalse(passage.usedDemoFixture)
        XCTAssertEqual(passage.text, "Hello world.")
        XCTAssertFalse(passage.text.contains("demo"))

        #if os(iOS)
        XCTAssertEqual(SpeechEngines.make(demoMode: false).engineName, "apple-speech-on-device")
        #else
        let speech = SpeechEngines.make(demoMode: false)
        XCTAssertEqual(speech.engineName, "unwired")
        #endif
    }

    func testOnDeviceRewriteTidiesWithoutInventingCopy() async throws {
        let engine = OnDeviceTextRewriter()
        let english = try await engine.rewrite("then i went", language: .english)
        XCTAssertEqual(english.text, "Then I went.")
        XCTAssertFalse(english.usedDemoFixture)

        let sentences = try await engine.rewrite("hello world. next sentence", language: .english)
        XCTAssertEqual(sentences.text, "Hello world. Next sentence.")
        let excited = try await engine.rewrite("wow!", language: .english)
        XCTAssertEqual(excited.text, "Wow!")

        let branded = try await engine.rewrite("iOS 17 is ready", language: .english)
        XCTAssertEqual(branded.text, "iOS 17 is ready.")

        let chinese = try await engine.rewrite("  周五前  把提纲发给我  ", language: .simplifiedChinese)
        XCTAssertEqual(chinese.text, "周五前把提纲发给我。")
        XCTAssertFalse(chinese.text.contains("演示"))

        let japanese = try await engine.rewrite(" 金曜  までに ", language: .japanese)
        XCTAssertEqual(japanese.text, "金曜までに。")

        let punctuated = try await engine.rewrite("已经有句号。", language: .simplifiedChinese)
        XCTAssertEqual(punctuated.text, "已经有句号。")

        do {
            _ = try await engine.rewrite(" \n\t ", language: .english)
            XCTFail("Expected emptySource")
        } catch RewriteFailure.emptySource {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testFreshPreferencesPreferOnDeviceSpeech() {
        let suite = "group.test.keyboardapp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let loaded = PreferenceStore.load(from: defaults)
        XCTAssertEqual(loaded.language, .simplifiedChinese)
        XCTAssertFalse(loaded.demoModeEnabled)
        XCTAssertTrue(KeyboardPreferences.builtInFallback.demoModeEnabled)
        defaults.removePersistentDomain(forName: suite)
    }

    func testSpeechLocalesAndFailureCopy() {
        XCTAssertEqual(TypingLanguage.simplifiedChinese.speechLocaleIdentifier, "zh-CN")
        XCTAssertEqual(TypingLanguage.english.speechLocaleIdentifier, "en-US")
        XCTAssertEqual(TypingLanguage.japanese.speechLocaleIdentifier, "ja-JP")

        let denied = L10n.Keyboard.speechFailure(for: .speechDenied)
        XCTAssertFalse(denied.detail.isEmpty)
        let audio = L10n.Keyboard.speechFailure(for: .audioSessionFailed(code: 561015905))
        XCTAssertTrue(audio.detail.contains("561015905"))
        let silent = L10n.Keyboard.speechFailure(for: .noSpeech)
        XCTAssertEqual(silent.title, L10n.Keyboard.voiceEmptyTitle)
    }

    func testDictationFinishIsSticky() {
        let control = DictationControl()
        XCTAssertFalse(control.isFinishRequested)
        control.requestFinish()
        XCTAssertTrue(control.isFinishRequested)
        let finished = FinishFlag()
        control.onFinish { finished.mark() }
        XCTAssertTrue(finished.value)
    }

    func testSpeechAccessAndProductPolicy() {
        XCTAssertFalse(ProductPolicy.trackingEnabled)
        XCTAssertFalse(ProductPolicy.purchasesEnabled)
        XCTAssertFalse(ProductPolicy.advertisingEnabled)
        XCTAssertFalse(ProductPolicy.serverSpeechFallbackEnabled)
        XCTAssertFalse(ProductPolicy.bundlesWhisperKit)
        XCTAssertFalse(ProductPolicy.bundlesLlamaRuntime)
        #if !os(iOS)
        let snapshot = OnDeviceSpeechAccess.current(language: .english)
        XCTAssertEqual(snapshot.speech, .unavailable)
        XCTAssertEqual(snapshot.microphone, .unavailable)
        XCTAssertNil(snapshot.onDeviceSupported)
        XCTAssertEqual(snapshot.localeIdentifier, "en-US")
        XCTAssertFalse(snapshot.canDictate)
        #endif
    }

    func testPreferenceRoundTrip() {
        let suite = "group.test.keyboardapp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let loadedDefault = PreferenceStore.load(from: defaults)
        XCTAssertEqual(loadedDefault.language, KeyboardPreferences.builtInFallback.language)
        XCTAssertFalse(loadedDefault.demoModeEnabled)

        let saved = KeyboardPreferences(language: .japanese, demoModeEnabled: false)
        PreferenceStore.save(saved, to: defaults)
        XCTAssertEqual(PreferenceStore.load(from: defaults), saved)
        defaults.removePersistentDomain(forName: suite)
    }

    func testIdentifiersAreClaimable() {
        XCTAssertEqual(AppIdentity.appBundleIdentifier, "com.mosquito1123.keyboardapp")
        XCTAssertEqual(AppIdentity.keyboardBundleIdentifier, "com.mosquito1123.keyboardapp.keyboard")
        XCTAssertEqual(AppIdentity.appGroupIdentifier, "group.com.mosquito1123.keyboardapp")
        XCTAssertFalse(AppIdentity.appBundleIdentifier.contains("example"))
        XCTAssertFalse(AppIdentity.appGroupIdentifier.contains("example"))
        XCTAssertFalse(ProductPolicy.trackingEnabled)
    }

    func testTonePresetsStayOnDevice() async throws {
        let engine = OnDeviceTextRewriter()

        let shorterChinese = try await engine.rewrite("然后我其实真的想把提纲发给你啊", language: .simplifiedChinese, tone: .shorter)
        XCTAssertEqual(shorterChinese.text, "我其实真的想把提纲发给你。")
        XCTAssertEqual(shorterChinese.engineName, "on-device-tone")
        XCTAssertFalse(shorterChinese.usedDemoFixture)

        let shorterEnglish = try await engine.rewrite("I just really need the outline.", language: .english, tone: .shorter)
        XCTAssertEqual(shorterEnglish.text, "I need the outline.")

        let formalChinese = try await engine.rewrite("马上搞定，谢谢你", language: .simplifiedChinese, tone: .formal)
        XCTAssertEqual(formalChinese.text, "立即完成，感谢您。")

        let formalEnglish = try await engine.rewrite("yeah I can't do that", language: .english, tone: .formal)
        XCTAssertEqual(formalEnglish.text, "Yes I cannot do that.")

        let casualChinese = try await engine.rewrite("请您立即处理", language: .simplifiedChinese, tone: .casual)
        XCTAssertEqual(casualChinese.text, "你马上处理。")

        let casualEnglish = try await engine.rewrite("I cannot do that. Thank you.", language: .english, tone: .casual)
        XCTAssertEqual(casualEnglish.text, "I can't do that. Thanks.")

        let shorterJapanese = try await engine.rewrite("ちょっとあの金曜までにね", language: .japanese, tone: .shorter)
        XCTAssertEqual(shorterJapanese.text, "金曜までに。")

        let polish = try await engine.rewrite("then i went", language: .english, tone: .polish)
        XCTAssertEqual(polish.text, "Then I went.")
        XCTAssertEqual(polish.engineName, "on-device-tidy")
    }

    func testDemoToneUsesHeuristicsExceptPolish() async throws {
        let demo = DemoTextRewriter(delayNanoseconds: 1_000_000)
        let polish = try await demo.rewrite("下午见", language: .english, tone: .polish)
        XCTAssertEqual(polish.text, "(demo rewrite) 下午见.")
        XCTAssertTrue(polish.usedDemoFixture)

        let shorter = try await demo.rewrite("I just really need the outline.", language: .english, tone: .shorter)
        XCTAssertEqual(shorter.text, "I need the outline.")
        XCTAssertFalse(shorter.usedDemoFixture)
    }

    func testInProcessStoreWhenGroupIsOff() {
        #if os(Linux)
        XCTAssertFalse(SharedStore.usesAppGroup)
        XCTAssertNil(SharedStore.defaults())
        #endif
        let defaults = UserDefaults.standard
        let saved = KeyboardPreferences(language: .english, demoModeEnabled: true)
        PreferenceStore.save(saved, to: defaults)
        XCTAssertEqual(PreferenceStore.load(from: defaults).language, .english)
        defaults.removeObject(forKey: "kp.language")
        defaults.removeObject(forKey: "kp.demoMode")
    }

    func testVoiceCopyIsShortAndActionable() {
        let locked = L10n.Keyboard.idleDetail(
            language: .simplifiedChinese,
            demoEnabled: true,
            synced: false,
            shared: false
        )
        XCTAssertFalse(locked.contains("语音条"))
        XCTAssertFalse(locked.contains("设置未共享"))
        XCTAssertTrue(locked.contains("完全访问"))
        XCTAssertLessThan(locked.count, 48)

        let ready = L10n.Keyboard.idleDetail(
            language: .english,
            demoEnabled: false,
            synced: true,
            shared: false
        )
        XCTAssertTrue(ready.contains("EN"))
        XCTAssertTrue(ready.contains("点一下"))
        XCTAssertFalse(L10n.Keyboard.voiceIdleTitle.contains("语音条"))
        XCTAssertFalse(L10n.Keyboard.rewriteStaleDetail.isEmpty)
        XCTAssertFalse(L10n.Keyboard.rewriteEmptyTitle.isEmpty)
    }

    func testThemeKeepsWarmInkInBothAppearances() {
        XCTAssertNotEqual(Theme.canvas.light, Theme.canvas.dark)
        XCTAssertGreaterThan(Theme.canvas.light.red, Theme.canvas.dark.red)
        XCTAssertEqual(Theme.mic.light, Theme.mic.dark)
        XCTAssertGreaterThan(Theme.keyFillPressed.dark.red, 0.5)
        XCTAssertLessThan(Theme.cream.light.red, 0.3)
        XCTAssertGreaterThan(Theme.cream.dark.red, 0.8)
    }

    func testKeyboardInstallListMatchesExtensionId() {
        let id = AppIdentity.keyboardBundleIdentifier
        XCTAssertTrue(KeyboardInstallStatus.isListed([id], bundleIdentifier: id))
        XCTAssertTrue(KeyboardInstallStatus.isListed(["\(id) (zh_CN)"], bundleIdentifier: id))
        XCTAssertFalse(KeyboardInstallStatus.isListed([AppIdentity.appBundleIdentifier], bundleIdentifier: id))
        XCTAssertFalse(KeyboardInstallStatus.isListed([], bundleIdentifier: id))
        XCTAssertEqual(AppIdentity.releaseVersion, "0.5.0")
    }

    func testPunctuationFollowsLanguage() {
        XCTAssertEqual(TypingLanguage.simplifiedChinese.commaMark, "，")
        XCTAssertEqual(TypingLanguage.english.commaMark, ",")
        XCTAssertEqual(TypingLanguage.japanese.periodMark, "。")
        XCTAssertEqual(TypingLanguage.english.periodMark, ".")
    }
}
