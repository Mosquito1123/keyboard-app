import Foundation

public enum LanguageModelStubError: Error, Equatable, Sendable {
    /// No model weights and no network client are linked.
    case notImplemented
}

/// Placeholder for a future on-device language model.
/// `complete` does not allocate a model and does not contact a server.
public struct LanguageModelStub: Sendable {
    public init() {}

    public static let scopeNote = "No on-device language model is linked."

    public func complete(prompt: String) async throws -> String {
        _ = prompt
        throw LanguageModelStubError.notImplemented
    }
}
