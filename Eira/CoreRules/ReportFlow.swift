import Foundation
import Observation

@MainActor @Observable
final class ReportFlow {
    enum Stage { case review, confirmation, form }

    private let store: any EiraStore
    private let client: any ServerClient
    private var active = true
    private(set) var draft = ReportDraft()
    private(set) var isWorking = false
    private(set) var stage = Stage.review
    private(set) var deliveryDraft: ReportDraft?
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
        dependencies.lifetime?.onLock { [weak self] in
            self?.active = false
            self?.draft = ReportDraft()
            self?.deliveryDraft = nil
            self?.stage = .review
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
            if active { draft = loaded }
        }
        catch { if active { errorMessage = "Drafmu belum bisa dibuka. Coba lagi." } }
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
        } catch { if active { errorMessage = "Draf belum bisa diperbarui. Draf yang tersimpan tetap ada." } }
    }

    func edit(_ name: ReportFieldName, text: String) async -> Bool {
        guard active else { return false }
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
            guard active else { return false }
            draft = updated
            errorMessage = nil
            return true
        } catch {
            guard active else { return false }
            errorMessage = "Perubahanmu belum tersimpan. Coba lagi."
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
        } catch { if active { errorMessage = "Draf belum bisa diperiksa. Formulir belum dibuka." } }
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
                errorMessage = "Draf atau izin penggunaan catatan berubah. Periksa kembali sebelum membuka formulir."
                return
            }
            guard active else { return }
            stage = .form
        } catch {
            guard active else { return }
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
            let checked = try await currentDraft()
            guard active else { return nil }
            draft = checked
            guard let value = draft.fields.first(where: { $0.fieldName == name })?.value else { return nil }
            return ReportFields.text(value)
        } catch {
            guard active else { return nil }
            errorMessage = "Isian belum bisa disalin. Coba lagi."
            return nil
        }
    }
}
