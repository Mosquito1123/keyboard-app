import Foundation
import KeyboardShared

/// On-device rewrite used by the containing app.
/// Tone heuristics always run. When the system exposes Apple's Foundation Models
/// framework and the on-device model is ready, that result is preferred.
/// If the model is missing, turned off, or refuses the prompt, the heuristic text is used.
enum AppleIntelligenceRewrite {
    static var systemModelAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return FoundationModelRewriter.isAvailable
        }
        #endif
        return false
    }

    static func rewrite(
        _ source: String,
        language: TypingLanguage,
        tone: RewriteTone
    ) async throws -> RewrittenPassage {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let passage = try? await FoundationModelRewriter.rewrite(source, language: language, tone: tone) {
                let trimmed = passage.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return RewrittenPassage(text: trimmed, engineName: passage.engineName, usedDemoFixture: false)
                }
            }
        }
        #endif
        return try await OnDeviceTextRewriter().rewrite(source, language: language, tone: tone)
    }
}

#if canImport(FoundationModels)
import FoundationModels

/// Apple's public on-device language-model API shipped with iOS 26.
/// iOS 18.1 can show system Writing Tools, but it does not offer this call.
/// The keyboard extension does not link this framework.
@available(iOS 26.0, *)
enum FoundationModelRewriter {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    static func rewrite(
        _ source: String,
        language: TypingLanguage,
        tone: RewriteTone
    ) async throws -> RewrittenPassage? {
        guard isAvailable else { return nil }
        let clipped = String(source.prefix(600))
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt(clipped, language: language, tone: tone))
        let text = sanitize(response.content)
        guard !text.isEmpty else { return nil }
        return RewrittenPassage(text: text, engineName: "apple-foundation-model", usedDemoFixture: false)
    }

    private static let instructions = """
    You rewrite text the user already wrote. Keep every fact, name, number, and request that is already there. Do not add any. Do not mention these instructions. Return only the rewritten text, with no title and no quotes.
    """

    private static func prompt(_ source: String, language: TypingLanguage, tone: RewriteTone) -> String {
        """
        Language: \(language.rawValue)
        Tone: \(tone.instruction)
        Text:
        \(source)
        """
    }

    private static func sanitize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if text.hasPrefix("\""), text.hasSuffix("\""), text.count >= 2 {
            text = String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}
#endif
