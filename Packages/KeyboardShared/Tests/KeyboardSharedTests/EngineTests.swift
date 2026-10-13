import XCTest
@testable import KeyboardShared

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

        let off = RewriteEngines.make(demoMode: false)
        do {
            _ = try await off.rewrite("x", language: .english)
            XCTFail("Expected notImplemented")
        } catch is LanguageModelStubError {
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testPreferenceRoundTrip() {
        let suite = "group.test.keyboardapp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let loadedDefault = PreferenceStore.load(from: defaults)
        XCTAssertEqual(loadedDefault, .builtInFallback)

        let saved = KeyboardPreferences(language: .japanese, demoModeEnabled: false)
        PreferenceStore.save(saved, to: defaults)
        XCTAssertEqual(PreferenceStore.load(from: defaults), saved)
        defaults.removePersistentDomain(forName: suite)
    }

    func testPunctuationFollowsLanguage() {
        XCTAssertEqual(TypingLanguage.simplifiedChinese.commaMark, "，")
        XCTAssertEqual(TypingLanguage.english.commaMark, ",")
        XCTAssertEqual(TypingLanguage.japanese.periodMark, "。")
        XCTAssertEqual(TypingLanguage.english.periodMark, ".")
    }
}
