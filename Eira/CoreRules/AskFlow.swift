import Foundation
import Observation

@MainActor @Observable
final class AskFlow {
    struct Turn: Identifiable {
        let entry: Entry
        var response: AskResponse?
        var id: UUID { entry.id }
    }

    private let store: any EiraStore
    private let client: any ServerClient
    private var active = true
    private var replies: [UUID: AskResponse] = [:]
    private var replySources: [UUID: Set<UUID>] = [:]
    private(set) var turns: [Turn] = []
    private(set) var isWorking = false
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
        dependencies.lifetime?.onLock { [weak self] in
            self?.active = false
            self?.turns = []
            self?.replies = [:]
            self?.replySources = [:]
            self?.errorMessage = nil
        }
    }

    static func needsLawyerCaveat(_ response: AskResponse) -> Bool {
        !Set(response.faqAnswersUsed).isDisjoint(with: [4, 7, 11])
    }

    private func show(_ entries: [Entry]) {
        guard active else { return }
        let allowedIDs = Set(entries.filter { $0.allowedUses.legalGuidance }.map(\.id))
        // A previous answer may contain a story whose permission has since changed.
        replies = replies.filter { replySources[$0.key, default: []].isSubset(of: allowedIDs) }
        turns = entries.filter { $0.kind == .question && $0.allowedUses.legalGuidance }
            .sorted { $0.createdAt < $1.createdAt }
            .map { Turn(entry: $0, response: replies[$0.id]) }
    }

    func load() async {
        do { show(try await store.entries()) }
        catch { if active { errorMessage = "Pertanyaanmu belum bisa dibuka. Coba lagi." } }
    }

    func send(_ text: String) async -> Bool {
        guard active, !isWorking, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let question = Entry(text: text, kind: .question)
            try await store.saveEntry(question)
            return await answer(question)
        } catch {
            guard active else { return false }
            errorMessage = "Pertanyaanmu belum tersimpan. Coba lagi."
            return false
        }
    }

    func retry(_ entry: Entry) async {
        guard active, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        _ = await answer(entry)
    }

    private func answer(_ question: Entry) async -> Bool {
        do {
            let entries = try await store.entries()
            show(entries)
            guard entries.contains(where: { $0.id == question.id && $0.allowedUses.legalGuidance }) else { return true }
            let earlier = turns.prefix { $0.id != question.id }
            let conversation = earlier.flatMap { turn -> [AskMessage] in
                var messages = [AskMessage(role: .user, text: turn.entry.text)]
                if let response = turn.response { messages.append(AskMessage(role: .assistant, text: response.answer)) }
                return messages
            }
            let sources = entries.filter { $0.allowedUses.legalGuidance }
            let response = try await client.ask(AskRequest(
                question: question.text, conversation: conversation,
                entries: sources.filter { $0.id != question.id }, events: try await store.events()))
            guard active, !Task.isCancelled else { return true }
            let current = try await store.entries()
            guard active else { return true }
            let sourceIDs = Set(sources.map(\.id))
            let currentIDs = Set(current.filter { $0.allowedUses.legalGuidance }.map(\.id))
            if sourceIDs.isSubset(of: currentIDs) {
                replies[question.id] = response
                replySources[question.id] = sourceIDs
            }
            show(current)
            return true
        } catch {
            guard active else { return true }
            errorMessage = "Jawabannya belum bisa dimuat. Pertanyaanmu tetap tersimpan. Kamu bisa mencoba lagi."
            // The question was saved; clear the composer without creating a duplicate on retry.
            return true
        }
    }
}
