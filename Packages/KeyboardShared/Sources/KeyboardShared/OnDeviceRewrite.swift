import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

public enum RewriteFailure: Error, Equatable, Sendable {
    case emptySource
}

/// Local tidy-up. Not a language model.
/// On Apple platforms the pass also consults `NLTagger` / `NLTokenizer`.
/// The visible result is still a light cleanup: spacing, sentence case, and a closing mark.
public struct OnDeviceTextRewriter: TextRewriting {
    public var engineName: String { "on-device-tidy" }

    public init() {}

    public func rewrite(_ source: String, language: TypingLanguage) async throws -> RewrittenPassage {
        let text = try OnDeviceRewrite.tidy(source, language: language)
        return RewrittenPassage(text: text, engineName: engineName, usedDemoFixture: false)
    }
}

enum OnDeviceRewrite {
    static func tidy(_ source: String, language: TypingLanguage) throws -> String {
        var text = source.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if language != .english {
            text = stripSpacesBetweenCJK(text)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw RewriteFailure.emptySource
        }
        text = polish(text, language: language)
        return ensureTerminal(text, language: language)
    }

    private static func polish(_ text: String, language: TypingLanguage) -> String {
        #if canImport(NaturalLanguage)
        return NaturalLanguagePolish.apply(text, language: language)
        #else
        return HeuristicPolish.apply(text, language: language)
        #endif
    }

    static func stripSpacesBetweenCJK(_ text: String) -> String {
        let chars = Array(text)
        var result = ""
        result.reserveCapacity(chars.count)
        for index in chars.indices {
            let character = chars[index]
            if character == " " || character == "\u{3000}" {
                let previous = index > chars.startIndex ? chars[chars.index(before: index)] : nil
                let nextIndex = chars.index(after: index)
                let next = nextIndex < chars.endIndex ? chars[nextIndex] : nil
                if let previous, let next, isCJK(previous), isCJK(next) {
                    continue
                }
            }
            result.append(character)
        }
        return result
    }

    static func isCJK(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            let value = scalar.value
            return (0x3400...0x4DBF).contains(value)
                || (0x4E00...0x9FFF).contains(value)
                || (0x3040...0x30FF).contains(value)
                || (0x3000...0x303F).contains(value)
                || (0xFF00...0xFFEF).contains(value)
        }
    }

    static func ensureTerminal(_ text: String, language: TypingLanguage) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last else { return trimmed }
        let terminals: Set<Character> = [".", "!", "?", "。", "！", "？", "…"]
        if terminals.contains(last) {
            return trimmed
        }
        return trimmed + language.periodMark
    }
}

enum HeuristicPolish {
    static func apply(_ text: String, language: TypingLanguage) -> String {
        guard language == .english else { return text }
        return capitalizeStandaloneI(capitalizeSentences(text))
    }

    static func capitalizeSentences(_ text: String) -> String {
        var result = ""
        var capitalizeNext = true
        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if capitalizeNext {
                if character.isWhitespace {
                    result.append(character)
                } else {
                    let following = index + 1 < characters.count ? characters[index + 1] : nil
                    if shouldCapitalize(character, next: following) {
                        result.append(contentsOf: String(character).uppercased())
                    } else {
                        result.append(character)
                    }
                    capitalizeNext = false
                }
            } else {
                result.append(character)
                if character == "." || character == "!" || character == "?" || character == "。" || character == "！" || character == "？" {
                    capitalizeNext = true
                }
            }
            index += 1
        }
        return result
    }

    /// Leaves a leading lowercase letter alone when the next letter is already uppercase (`iOS`).
    static func shouldCapitalize(_ character: Character, next: Character?) -> Bool {
        guard character.isASCII, character.isLetter, String(character) == String(character).lowercased() else {
            return false
        }
        if let next, next.isLetter, String(next) == String(next).uppercased() {
            return false
        }
        return true
    }

    static func capitalizeStandaloneI(_ text: String) -> String {
        var result = ""
        var token = ""
        func flush() {
            if token == "i" {
                result.append("I")
            } else {
                result.append(token)
            }
            token.removeAll(keepingCapacity: true)
        }
        for character in text {
            if character.isLetter {
                token.append(character)
            } else {
                flush()
                result.append(character)
            }
        }
        flush()
        return result
    }

    static func capitalizingFirstLetter(_ text: String) -> String {
        var characters = Array(text)
        guard let index = characters.firstIndex(where: { !$0.isWhitespace && !$0.isNewline }) else {
            return text
        }
        let character = characters[index]
        let next = characters.index(after: index)
        let following = next < characters.endIndex ? characters[next] : nil
        guard shouldCapitalize(character, next: following) else {
            return text
        }
        characters[index] = Character(String(character).uppercased())
        return String(characters)
    }
}

#if canImport(NaturalLanguage)
enum NaturalLanguagePolish {
    static func apply(_ text: String, language: TypingLanguage) -> String {
        let promoted = promotePronounI(text, language: language)
        if language == .english, let tokenized = capitalizeWithTokenizer(promoted) {
            return HeuristicPolish.capitalizeStandaloneI(tokenized)
        }
        return HeuristicPolish.apply(promoted, language: language)
    }

    /// Uses `NLTagger` lexical class so a standalone English pronoun "i" becomes "I"
    /// when the tagger agrees. The heuristic pass still catches anything the tagger skips.
    private static func promotePronounI(_ text: String, language: TypingLanguage) -> String {
        guard language == .english, !text.isEmpty else { return text }
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let full = text.startIndex..<text.endIndex
        tagger.setLanguage(.english, range: full)
        var result = text
        var replacements: [(Range<String.Index>, String)] = []
        tagger.enumerateTags(in: full, unit: .word, scheme: .lexicalClass, options: []) { tag, range in
            if tag == .pronoun, text[range] == "i" {
                replacements.append((range, "I"))
            }
            return true
        }
        for (range, replacement) in replacements.reversed() {
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }

    /// Sentence spans come from `NLTokenizer` when they cover the string.
    /// Each span is copied from the original and only the first letter may change.
    private static func capitalizeWithTokenizer(_ text: String) -> String? {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var pieces: [String] = []
        var cursor = text.startIndex
        var sawToken = false
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            sawToken = true
            if cursor < range.lowerBound {
                pieces.append(String(text[cursor..<range.lowerBound]))
            }
            pieces.append(HeuristicPolish.capitalizingFirstLetter(String(text[range])))
            cursor = range.upperBound
            return true
        }
        guard sawToken else { return nil }
        if cursor < text.endIndex {
            pieces.append(String(text[cursor...]))
        }
        return pieces.joined()
    }
}
#endif
