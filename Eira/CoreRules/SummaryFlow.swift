import Foundation
import Observation

@MainActor @Observable
final class SummaryFlow {
    private let store: any EiraStore
    private var active = true
    private(set) var facts: [TalkFact] = []
    private(set) var references: [LegalReferences.Reference] = []
    private(set) var isSaving = false
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        dependencies.lifetime?.onLock { [weak self] in
            self?.active = false
            self?.facts = []
            self?.references = []
            self?.errorMessage = nil
        }
    }

    func load() async {
        do {
            let entries = try await store.entries()
            let stored = try await store.talkFacts()
            let events = try await store.events()
            guard active else { return }
            facts = TalkFacts.visible(stored, entries: entries)
            references = LegalReferences.references(entries: entries, events: events)
        } catch { if active { errorMessage = "This summary could not be opened. Try again." } }
    }

    func value(for category: TalkFactCategory) -> String {
        facts.filter { $0.category == category && !$0.value.isEmpty }.map(\.value).joined(separator: " · ")
    }

    func isEdited(_ category: TalkFactCategory) -> Bool {
        facts.contains { $0.category == category && $0.userEdited && !$0.value.isEmpty }
    }

    // Her words replace the category. An emptied fix stays as a marker so the AI cannot refill it.
    func fix(_ category: TalkFactCategory, text: String) async -> Bool {
        guard active, !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let stored = try await store.talkFacts()
            let replaced = stored.filter { $0.category == category }
            for fact in replaced where fact.userEdited {
                if let id = fact.sourceEntryID { try await store.deleteEntry(id: id) }
            }
            var kept = try await store.talkFacts().filter { $0.category != category }
            if value.isEmpty {
                kept.append(TalkFact(category: category, value: "", quote: nil, sourceEntryID: nil, userEdited: true))
            } else {
                let entry = Entry(text: "\(SafetyStrings.factLabel(category)): \(value)", kind: .correction)
                try await store.saveEntry(entry)
                kept.append(TalkFact(category: category, value: value, quote: value, sourceEntryID: entry.id, userEdited: true))
            }
            try await store.saveTalkFacts(kept)
            await load()
            return true
        } catch {
            if active { errorMessage = "Your change could not be saved. Try again." }
            return false
        }
    }
}

enum TalkFacts {
    // Facts only show while their source is allowed; a fix she cleared has no source and stays hidden by value.
    static func visible(_ facts: [TalkFact], entries: [Entry]) -> [TalkFact] {
        let allowed = entries.filter { $0.allowedUses.legalGuidance }
        return facts.filter { fact in
            guard let id = fact.sourceEntryID else { return fact.userEdited }
            guard let source = allowed.first(where: { $0.id == id }) else { return false }
            return QuoteCheck.contains(fact.quote, in: source.text)
        }
    }

    // Quote-checks new facts against her words. Her fixes win over the AI for that category.
    static func merged(_ incoming: [TalkFactResponse], into existing: [TalkFact],
                       sources: [Entry]) -> (all: [TalkFact], added: [UUID]) {
        var all = existing
        var added: [UUID] = []
        let quotable = sources.filter { $0.allowedUses.legalGuidance && $0.source != .quickReply }
        for fact in incoming {
            guard !all.contains(where: { $0.category == fact.category && $0.userEdited }),
                  // The model rewords a fact it already gave, so the same quote counts as the same fact.
                  !all.contains(where: { $0.category == fact.category
                      && (QuoteCheck.normalize($0.value) == QuoteCheck.normalize(fact.value)
                          || sharesQuote($0.quote, fact.quote)) }),
                  !fact.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let source = quotable.first(where: { QuoteCheck.contains(fact.quote, in: $0.text) })
            else { continue }
            let checked = TalkFact(category: fact.category, value: fact.value, quote: fact.quote, sourceEntryID: source.id)
            all.append(checked)
            added.append(checked.id)
        }
        return (all, added)
    }

    private static func sharesQuote(_ first: String?, _ second: String) -> Bool {
        guard let first else { return false }
        let (a, b) = (QuoteCheck.normalize(first), QuoteCheck.normalize(second))
        return !a.isEmpty && !b.isEmpty && (a.contains(b) || b.contains(a))
    }
}
