import Foundation

public enum LanguageModelStubError: Error, Equatable, Sendable {
    /// No model weights and no network client are linked.
    case notImplemented
}

public struct RewrittenPassage: Sendable, Equatable {
    public var text: String
    public var engineName: String
    public var usedDemoFixture: Bool

    public init(text: String, engineName: String, usedDemoFixture: Bool) {
        self.text = text
        self.engineName = engineName
        self.usedDemoFixture = usedDemoFixture
    }
}

/// On-device rewrite entry point. One style only, so the keyboard stays a single control.
public protocol TextRewriting: Sendable {
    var engineName: String { get }
    func rewrite(_ source: String, language: TypingLanguage) async throws -> RewrittenPassage
}

public struct DemoTextRewriter: TextRewriting {
    public var engineName: String { "demo-fixture" }
    public var delayNanoseconds: UInt64

    public init(delayNanoseconds: UInt64 = 650_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    public func rewrite(_ source: String, language: TypingLanguage) async throws -> RewrittenPassage {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return RewrittenPassage(
            text: language.demoRewrite(of: source),
            engineName: engineName,
            usedDemoFixture: true
        )
    }
}

public struct UnwiredTextRewriter: TextRewriting {
    public var engineName: String { "unwired" }

    public init() {}

    public func rewrite(_ source: String, language: TypingLanguage) async throws -> RewrittenPassage {
        _ = source
        _ = language
        throw LanguageModelStubError.notImplemented
    }
}

public enum RewriteEngines {
    /// Demo fixtures are the only rewriter linked today.
    /// This package does not depend on llama.cpp or any other model runtime.
    public static func make(demoMode: Bool, delayNanoseconds: UInt64 = 650_000_000) -> any TextRewriting {
        if demoMode {
            return DemoTextRewriter(delayNanoseconds: delayNanoseconds)
        }
        return UnwiredTextRewriter()
    }
}

/// Placeholder for a future on-device language model.
/// `complete` does not allocate a model and does not contact a server.
/// Demo rewriting goes through `RewriteEngines`, not this method.
public struct LanguageModelStub: Sendable {
    public init() {}

    public static let scopeNote = "No on-device model runtime is linked. Demo rewrite uses RewriteEngines."

    public func complete(prompt: String) async throws -> String {
        _ = prompt
        throw LanguageModelStubError.notImplemented
    }
}
