import Foundation

enum QuoteCheck {
    static func normalize(_ text: String) -> String {
        let compatible = text.precomposedStringWithCompatibilityMapping.lowercased()
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
        let scalars = compatible.unicodeScalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0)
                || CharacterSet.whitespacesAndNewlines.contains($0)
        }
        return String(String.UnicodeScalarView(scalars))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func contains(_ quote: String?, in text: String) -> Bool {
        guard let quote else { return false }
        let normalizedQuote = normalize(quote)
        return !normalizedQuote.isEmpty && normalize(text).contains(normalizedQuote)
    }

    static func validated(_ event: Event, against entry: Entry) -> Event? {
        guard event.entryID == entry.id, entry.kind == .story,
              contains(event.quote, in: entry.text) else { return nil }
        return event
    }

    // Call with her entries only. AI replies are not quote sources.
    static func validated(_ field: ReportDraftField, against entries: [Entry]) -> ReportDraftField {
        guard field.status != .editedByHer else { return field }
        guard field.value != nil,
              let source = entries.first(where: { $0.allowedUses.report && contains(field.quote, in: $0.text) })
        else { return ReportDraftField(fieldName: field.fieldName) }
        var checked = field
        checked.sourceEntryID = source.id
        checked.status = .fromHerWords
        return checked
    }
}
