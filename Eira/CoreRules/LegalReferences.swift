import Foundation

// PROVISIONAL: fixed UU PKDRT table (C19), from the legal article map in AI_CONTRACTS.md,
// pending lawyer review. Plain code, no AI. Swap this file if the team changes the law shown.
enum LegalReferences {
    struct Reference: Identifiable, Equatable {
        let article: String
        let title: String
        let reason: String
        var id: String { article }
    }

    static let lawName = "UU 23/2004 (PKDRT)"

    static func reference(for type: ViolenceType) -> Reference? {
        switch type {
        case .physical: Reference(article: "Pasal 6", title: "Physical violence",
            reason: "You mentioned an incident involving unwanted physical contact.")
        case .psychological: Reference(article: "Pasal 7", title: "Psychological violence",
            reason: "You mentioned words or behaviour that hurt or frightened you.")
        case .sexual: Reference(article: "Pasal 8", title: "Sexual violence",
            reason: "You mentioned unwanted sexual contact or pressure.")
        case .neglect: Reference(article: "Pasal 9", title: "Household neglect",
            reason: "You mentioned being cut off from money or basic needs.")
        case .unsure: nil
        }
    }

    // One card per type, only from entries allowed for legal guidance.
    static func references(entries: [Entry], events: [Event]) -> [Reference] {
        let allowed = Set(entries.filter { $0.allowedUses.legalGuidance }.map(\.id))
        let types = Set(events.filter { allowed.contains($0.entryID) }.map(\.violenceType))
        return [ViolenceType.physical, .psychological, .sexual, .neglect]
            .filter(types.contains).compactMap(reference(for:))
    }
}
