import Foundation
import Observation

@MainActor @Observable
final class ReportFlow {
    enum Stage { case review, confirmation, form }

    private let store: any EiraStore
    private let client: any ServerClient
    private(set) var draft = ReportDraft()
    private(set) var isWorking = false
    private(set) var stage = Stage.review
    private(set) var deliveryDraft: ReportDraft?
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
    }

    private func currentDraft() async throws -> ReportDraft {
        let saved = try await store.reportDraft() ?? ReportDraft()
        return ReportFields.checked(saved, entries: try await store.entries())
    }

    func load() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do { draft = try await currentDraft() }
        catch { errorMessage = "Drafmu belum bisa dibuka. Coba lagi." }
    }

    func refresh() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let entries = try await store.entries()
            let response = try await client.draft(DraftRequest(entries: entries))
            let currentEntries = try await store.entries()
            let saved = try await store.reportDraft() ?? draft
            let updated = ReportFields.merged(response, keeping: saved, entries: currentEntries)
            try await store.saveReportDraft(updated)
            draft = updated
        } catch { errorMessage = "Draf belum bisa diperbarui. Draf yang tersimpan tetap ada." }
    }

    func edit(_ name: ReportFieldName, text: String) async -> Bool {
        let value = ReportFields.editedValue(text, for: name)
        guard ReportFields.valid(value, for: name) else {
            errorMessage = name == .victimAge ? "Isi usia dengan angka bulat 1 sampai 100."
                : ReportFields.isPhone(name) ? "Nomor telepon hanya boleh berisi angka 0–9."
                : "Pilih nilai yang tersedia, atau isi teks paling banyak 5.000 karakter."
            return false
        }
        do {
            var updated = try await currentDraft()
            if let index = updated.fields.firstIndex(where: { $0.fieldName == name }) {
                updated.fields[index] = ReportDraftField(fieldName: name, value: value, status: .editedByHer)
            }
            try await store.saveReportDraft(updated)
            draft = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Perubahanmu belum tersimpan. Coba lagi."
            return false
        }
    }

    func prepareConfirmation() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let checked = try await currentDraft()
            try await store.saveReportDraft(checked)
            draft = checked
            deliveryDraft = checked
            stage = .confirmation
        } catch { errorMessage = "Draf belum bisa diperiksa. Formulir belum dibuka." }
    }

    func openConfirmedForm() async {
        guard stage == .confirmation, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let checked = try await currentDraft()
            guard checked == deliveryDraft else {
                draft = checked
                closeDelivery()
                errorMessage = "Draf atau izin penggunaan catatan berubah. Periksa kembali sebelum membuka formulir."
                return
            }
            stage = .form
        } catch {
            closeDelivery()
            errorMessage = "Draf belum bisa diperiksa. Formulir belum dibuka."
        }
    }

    func closeDelivery() {
        stage = .review
        deliveryDraft = nil
    }

    func copyText(for name: ReportFieldName) async -> String? {
        do {
            draft = try await currentDraft()
            guard let value = draft.fields.first(where: { $0.fieldName == name })?.value else { return nil }
            return ReportFields.text(value)
        } catch {
            errorMessage = "Isian belum bisa disalin. Coba lagi."
            return nil
        }
    }
}
