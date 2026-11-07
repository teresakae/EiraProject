import Foundation
import Observation

@MainActor @Observable
final class WriteFlow {
    private let store: any EiraStore
    private let client: any ServerClient
    private var active = true
    private var operation: Task<Void, Never>?
    private(set) var entries: [Entry] = []
    private(set) var events: [Event] = []
    private(set) var isWorking = false
    var text = ""
    var source: EntrySource = .text
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
    }

    var timeline: [Event] {
        let ids = Set(entries.filter { $0.allowedUses.personalTimeline }.map(\.id))
        return events.filter { ids.contains($0.entryID) }
    }

    func load() async {
        do {
            let loaded = try await store.entries().filter { $0.kind == .story }.sorted { $0.createdAt < $1.createdAt }
            let extracted = try await store.events()
            guard active, !Task.isCancelled else { return }
            entries = loaded
            events = extracted.compactMap { event in
                guard let entry = loaded.first(where: { $0.id == event.entryID }) else { return nil }
                return QuoteCheck.validated(event, against: entry)
            }
        } catch { if active { errorMessage = "Your entries could not be opened. Try again." } }
    }

    func submit() {
        guard !isWorking else { return }
        let message = text
        let origin = source
        operation = Task { _ = await send(message, source: origin) }
    }

    @discardableResult
    func send(_ text: String, source: EntrySource = .text) async -> Bool {
        guard active, !isWorking, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        var saved = false
        do {
            let entry = Entry(text: text, source: source)
            try await store.saveEntry(entry)
            saved = true
            guard active else { return true }
            self.text = ""
            self.source = .text
            await load()
            try Task.checkCancellation()
            guard active else { return true }
            let response = try await client.extract(ExtractRequest(text: entry.text))
            try Task.checkCancellation()
            guard active else { return true }
            let checked = response.events.compactMap { $0.event(for: entry) }
            try await store.saveEvents(checked, for: entry.id)
            guard var current = try await store.entries().first(where: { $0.id == entry.id }) else { return true }
            current.writeReply = response.reply
            try await store.saveEntry(current)
            let title = response.coverTask.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, title != "Eira" else { throw StoreError.format }
            try await store.saveCoverTask(CoverTask(title: title))
            await load()
        } catch {
            if active, !Task.isCancelled {
                errorMessage = saved ? "Your entry is saved. Its reply or timeline could not be loaded."
                    : "Your entry could not be saved. Try again."
            }
        }
        return saved
    }

    func setUses(_ uses: AllowedUses, for id: UUID) async {
        do {
            guard var entry = try await store.entries().first(where: { $0.id == id }) else { return }
            entry.allowedUses = uses
            try await store.saveEntry(entry)
            await load()
        } catch { if active { errorMessage = "Your choices could not be saved. Try again." } }
    }

    func setType(_ type: ViolenceType, for id: UUID) async {
        do {
            var all = try await store.events()
            guard let index = all.firstIndex(where: { $0.id == id }) else { return }
            all[index].violenceType = type
            all[index].userEdited = true
            let entryID = all[index].entryID
            try await store.saveEvents(all.filter { $0.entryID == entryID }, for: entryID)
            await load()
        } catch { if active { errorMessage = "Your changes could not be saved. Try again." } }
    }

    func deleteEntry(_ id: UUID) async {
        do { try await store.deleteEntry(id: id); await load() }
        catch { if active { errorMessage = "Your entry could not be deleted. Try again." } }
    }

    func stop() {
        active = false
        operation?.cancel()
        operation = nil
        entries = []
        events = []
        text = ""
        source = .text
        errorMessage = nil
    }
}
