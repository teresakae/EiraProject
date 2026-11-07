import Foundation
import Observation

@MainActor @Observable
final class ReportFlow {
    enum Stage { case review, confirmation, form, afterSend }
    enum ContactPreference { case noPreference, noWhatsApp, whatsAppOK }

    private let store: any EiraStore
    private let client: any ServerClient
    private var active = true
    private(set) var draft = ReportDraft()
    private(set) var isWorking = false
    private(set) var stage = Stage.review
    private(set) var deliveryDraft: ReportDraft?
    private(set) var references: [LegalReferences.Reference] = []
    // Her choice for this visit only. It is not stored and resets on lock.
    var contactPreference = ContactPreference.noPreference
    var errorMessage: String?

    /// What the form receives and what the review screen shows.
    var formDraft: ReportDraft? {
        deliveryDraft.map { Self.withContactLine($0, preference: contactPreference) }
    }

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
        dependencies.lifetime?.onLock { [weak self] in
            self?.active = false
            self?.draft = ReportDraft()
            self?.deliveryDraft = nil
            self?.stage = .review
            self?.references = []
            self?.contactPreference = .noPreference
            self?.errorMessage = nil
        }
    }

    private func currentDraft() async throws -> ReportDraft {
        guard active else { throw StoreError.locked }
        let saved = try await store.reportDraft() ?? ReportDraft()
        let entries = try await store.entries()
        guard active else { throw StoreError.locked }
        return ReportFields.checked(saved, entries: entries)
    }

    func load() async {
        guard active, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let loaded = try await currentDraft()
            let entries = try await store.entries()
            let events = try await store.events()
            guard active else { return }
            draft = loaded
            references = LegalReferences.references(entries: entries, events: events)
        }
        catch { if active { errorMessage = "Your draft could not be opened. Try again." } }
    }

    // Builds the first draft on open. A draft holding any value or any edit of hers stays as it is.
    func fillIfEmpty() async {
        guard active, draft.fields.allSatisfy({ $0.value == nil && $0.status != .editedByHer }),
              let entries = try? await store.entries(),
              entries.contains(where: { $0.kind == .story && $0.allowedUses.report }) else { return }
        await refresh()
    }

    func refresh() async {
        guard active, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let entries = try await store.entries()
            let response = try await client.draft(DraftRequest(entries: entries))
            guard active, !Task.isCancelled else { return }
            let currentEntries = try await store.entries()
            let saved = try await store.reportDraft() ?? draft
            let updated = ReportFields.merged(response, keeping: saved, entries: currentEntries)
            try await store.saveReportDraft(updated)
            if active { draft = updated }
        } catch { if active { errorMessage = "The draft could not be refreshed. Your saved draft is unchanged." } }
    }

    func edit(_ name: ReportFieldName, text: String) async -> Bool {
        guard active else { return false }
        let value = ReportFields.editedValue(text, for: name)
        guard ReportFields.valid(value, for: name) else {
            errorMessage = name == .victimAge ? "Enter a whole-number age from 1 to 100."
                : ReportFields.isPhone(name) ? "Phone numbers can contain only digits 0–9."
                : "Choose an available value, or enter up to 5,000 characters."
            return false
        }
        do {
            var updated = try await currentDraft()
            if let index = updated.fields.firstIndex(where: { $0.fieldName == name }) {
                updated.fields[index] = ReportDraftField(fieldName: name, value: value, status: .editedByHer)
            }
            try await store.saveReportDraft(updated)
            guard active else { return false }
            draft = updated
            // She edited this from the review screen and sees the new value there.
            if stage == .confirmation { deliveryDraft = updated }
            errorMessage = nil
            return true
        } catch {
            guard active else { return false }
            errorMessage = "Your changes could not be saved. Try again."
            return false
        }
    }

    func prepareConfirmation() async {
        guard active, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let checked = try await currentDraft()
            try await store.saveReportDraft(checked)
            guard active else { return }
            draft = checked
            deliveryDraft = checked
            stage = .confirmation
        } catch { if active { errorMessage = "The draft could not be checked. The form has not been opened." } }
    }

    func openConfirmedForm() async {
        guard active, stage == .confirmation, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let checked = try await currentDraft()
            guard active else { return }
            guard checked == deliveryDraft else {
                draft = checked
                closeDelivery()
                errorMessage = "The draft or entry permissions changed. Review them again before opening the form."
                return
            }
            guard active else { return }
            stage = .form
        } catch {
            guard active else { return }
            closeDelivery()
            errorMessage = "The draft could not be checked. The form has not been opened."
        }
    }

    func finishForm() {
        guard stage == .form else { return }
        stage = .afterSend
    }

    func closeDelivery() {
        stage = .review
        deliveryDraft = nil
    }

    func copyAllText() async -> String? {
        do {
            let checked = try await currentDraft()
            guard active else { return nil }
            return Self.withContactLine(checked, preference: contactPreference).fields
                .filter { $0.value != nil }
                .map { "\(SafetyStrings.label($0.fieldName)): \(SafetyStrings.display($0.value, for: $0.fieldName))" }
                .joined(separator: "\n\n")
        } catch {
            guard active else { return nil }
            errorMessage = "The text could not be copied. Try again."
            return nil
        }
    }

    // The form has no contact-preference field, so her choice travels in the description.
    // ponytail: if the line would pass the form's limit it is left out, and the review shows that truthfully.
    static func withContactLine(_ draft: ReportDraft, preference: ContactPreference) -> ReportDraft {
        guard let line = SafetyStrings.contactLine(preference),
              let index = draft.fields.firstIndex(where: { $0.fieldName == .description }) else { return draft }
        let current = ReportFields.text(draft.fields[index].value)
        let combined = current.isEmpty ? line : "\(current)\n\n\(line)"
        guard ReportFields.valid(.text(combined), for: .description) else { return draft }
        var updated = draft
        updated.fields[index].value = .text(combined)
        return updated
    }

    func copyText(for name: ReportFieldName) async -> String? {
        do {
            let checked = try await currentDraft()
            guard active else { return nil }
            draft = checked
            guard let value = draft.fields.first(where: { $0.fieldName == name })?.value else { return nil }
            return ReportFields.text(value)
        } catch {
            guard active else { return nil }
            errorMessage = "The field could not be copied. Try again."
            return nil
        }
    }
}
