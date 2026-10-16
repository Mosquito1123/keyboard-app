import Foundation

/// Tone presets for the on-device rewriter.
/// `.polish` is the existing tidy-up. The others are local word-level passes.
/// None of them call a network or a bundled model.
public enum RewriteTone: String, CaseIterable, Sendable, Identifiable {
    case polish
    case shorter
    case formal
    case casual

    public var id: String { rawValue }

    public var title: (zh: String, en: String) {
        switch self {
        case .polish:
            return ("润色", "Polish")
        case .shorter:
            return ("更短", "Shorter")
        case .formal:
            return ("正式", "Formal")
        case .casual:
            return ("口语", "Casual")
        }
    }

    /// Instruction handed to Apple's on-device Foundation Model when that API is available.
    /// The heuristic pass does not read this string.
    public var instruction: String {
        switch self {
        case .polish:
            return "Fix spacing and punctuation. Keep the original wording and meaning."
        case .shorter:
            return "Make it shorter. Remove filler. Keep the request and the facts."
        case .formal:
            return "Make the wording formal and polite. Do not add new facts."
        case .casual:
            return "Make the wording conversational. Do not add new facts."
        }
    }
}

enum ToneRewrite {
    static func apply(_ tidied: String, language: TypingLanguage, tone: RewriteTone) throws -> String {
        let transformed: String
        switch tone {
        case .polish:
            transformed = tidied
        case .shorter:
            transformed = shorten(tidied, language: language)
        case .formal:
            transformed = formalize(tidied, language: language)
        case .casual:
            transformed = casualize(tidied, language: language)
        }
        let cleaned = collapseSpacing(transformed)
        guard !isEffectivelyEmpty(cleaned) else {
            throw RewriteFailure.emptySource
        }
        return OnDeviceRewrite.ensureTerminal(cleaned, language: language)
    }

    private static func shorten(_ text: String, language: TypingLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            var value = stripBoundedFillers(text, fillers: ["一下子", "就是说", "然后", "其实", "非常", "的话", "有点"])
            value = trimEdgeParticles(value, particles: ["啊", "呀", "哦", "呢", "吧", "嘛", "哈", "哟"])
            return value
        case .english:
            return replacePhrases(text, pairs: [
                ("kind of", ""),
                ("sort of", ""),
                ("you know", ""),
                ("a bit", ""),
                ("just", ""),
                ("really", ""),
                ("very", ""),
                ("actually", ""),
                ("basically", ""),
                ("literally", ""),
                ("please", ""),
                ("maybe", "")
            ])
        case .japanese:
            var value = stripBoundedFillers(text, fillers: ["ちょっと", "なんか", "あの", "まあ", "えー"])
            value = trimEdgeParticles(value, particles: ["ね", "よ", "な"])
            return value
        }
    }

    private static func formalize(_ text: String, language: TypingLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            var value = text
            let pairs = [("搞定", "完成"), ("不行", "无法"), ("马上", "立即"), ("谢谢", "感谢"), ("但是", "但")]
            for (from, to) in pairs {
                value = value.replacingOccurrences(of: from, with: to)
            }
            value = value.replacingOccurrences(of: "你", with: "您")
            value = trimEdgeParticles(value, particles: ["啊", "呀", "哦", "呢", "吧", "嘛", "哈", "哟"])
            if shouldPrefixPlease(value) {
                value = "请" + value
            }
            return value
        case .english:
            return replacePhrases(text, pairs: [
                ("gonna", "going to"),
                ("wanna", "want to"),
                ("gotta", "have to"),
                ("kinda", "somewhat"),
                ("yeah", "yes"),
                ("yep", "yes"),
                ("nope", "no"),
                ("thanks", "thank you"),
                ("hey", "hello"),
                ("hi", "hello"),
                ("can't", "cannot"),
                ("won't", "will not"),
                ("don't", "do not"),
                ("i'm", "I am"),
                ("it's", "it is"),
                ("we're", "we are"),
                ("they're", "they are"),
                ("that's", "that is"),
                ("there's", "there is")
            ])
        case .japanese:
            var value = text.replacingOccurrences(of: "じゃない", with: "ではありません")
            value = trimEdgeParticles(value, particles: ["ね", "よ"])
            return value
        }
    }

    private static func casualize(_ text: String, language: TypingLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            var value = text
            if value.hasPrefix("请") {
                value.removeFirst()
            }
            let pairs = [("您", "你"), ("因此", "所以"), ("但是", "不过"), ("立即", "马上"), ("感谢", "谢谢"), ("无法", "不行")]
            for (from, to) in pairs {
                value = value.replacingOccurrences(of: from, with: to)
            }
            return value
        case .english:
            return replacePhrases(text, pairs: [
                ("thank you", "thanks"),
                ("going to", "gonna"),
                ("want to", "wanna"),
                ("cannot", "can't"),
                ("will not", "won't"),
                ("do not", "don't"),
                ("hello", "hi"),
                ("it is", "it's"),
                ("i am", "I'm"),
                ("that is", "that's")
            ])
        case .japanese:
            return text.replacingOccurrences(of: "ではありません", with: "じゃない")
        }
    }

    /// Drops a filler only when it sits at the start of the string or just after punctuation.
    /// That avoids cutting the same characters out of a longer word.
    private static func stripBoundedFillers(_ text: String, fillers: [String]) -> String {
        let sorted = fillers.sorted { $0.count > $1.count }
        let breaks: Set<Character> = ["，", "。", "！", "？", "、", ",", ".", "!", "?", " ", "\n", "；", ";", "…"]
        var result = ""
        var index = text.startIndex
        var atBoundary = true
        while index < text.endIndex {
            if !atBoundary, index != text.startIndex, breaks.contains(text[text.index(before: index)]) {
                atBoundary = true
            }
            if atBoundary, let filler = sorted.first(where: { text[index...].hasPrefix($0) }) {
                index = text.index(index, offsetBy: filler.count)
                atBoundary = true
                continue
            }
            result.append(text[index])
            atBoundary = false
            index = text.index(after: index)
        }
        return result
    }

    private static func trimEdgeParticles(_ text: String, particles: [String]) -> String {
        let particleSet = Set(particles)
        let terminals: Set<Character> = [".", "!", "?", "。", "！", "？", "…"]
        var chars = Array(text)
        guard !chars.isEmpty else { return text }
        var end = chars.endIndex
        if let last = chars.last, terminals.contains(last) {
            end = chars.index(before: end)
        }
        while end > chars.startIndex {
            let index = chars.index(before: end)
            let piece = String(chars[index])
            if particleSet.contains(piece) {
                chars.remove(at: index)
                end = index
            } else {
                break
            }
        }
        return String(chars)
    }

    private static func shouldPrefixPlease(_ text: String) -> Bool {
        guard !text.contains("请") else { return false }
        let verbs = ["帮", "发", "送", "回复", "处理"]
        return verbs.contains { text.contains($0) }
    }

    private static func replacePhrases(_ text: String, pairs: [(String, String)]) -> String {
        var result = text
        let ordered = pairs.sorted { $0.0.count > $1.0.count }
        for (from, to) in ordered {
            result = replaceToken(result, from: from, to: to)
        }
        return result
    }

    private static func replaceToken(_ text: String, from: String, to: String) -> String {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: from))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let ns = text as NSString
        var output = text
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            let original = String(output[range])
            output.replaceSubrange(range, with: matchCase(to, like: original))
        }
        return output
    }

    private static func matchCase(_ replacement: String, like original: String) -> String {
        guard !replacement.isEmpty else { return replacement }
        let letters = original.filter(\.isLetter)
        if !letters.isEmpty, letters == letters.uppercased() {
            return replacement.uppercased()
        }
        guard let first = original.first, String(first) == String(first).uppercased() else {
            return replacement
        }
        return replacement.prefix(1).uppercased() + replacement.dropFirst()
    }

    private static func collapseSpacing(_ text: String) -> String {
        var value = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        for mark in [".", ",", "!", "?", "。", "，", "！", "？", "、", "…"] {
            value = value.replacingOccurrences(of: " \(mark)", with: mark)
        }
        while value.contains("，，") {
            value = value.replacingOccurrences(of: "，，", with: "，")
        }
        while value.hasPrefix("，") || value.hasPrefix(",") || value.hasPrefix("、") || value.hasPrefix(" ") {
            value.removeFirst()
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isEffectivelyEmpty(_ text: String) -> Bool {
        text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)).isEmpty
    }
}
