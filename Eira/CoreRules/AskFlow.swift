import Foundation
import Observation

@MainActor @Observable
final class AskFlow {
    struct Turn: Identifiable {
        let entry: Entry
        var response: AskResponse?
        var id: UUID { entry.id }
    }

    // A question Eira asks on her own: at the start, or after she skips.
    struct Prompt: Identifiable {
        let id = UUID()
        let text: String
        let afterTurn: UUID?
        let skipped: Bool
        let sources: Set<UUID>
    }

    private let store: any EiraStore
    private let client: any ServerClient
    private var active = true
    private var started = false
    private var replies: [UUID: AskResponse] = [:]
    private var replySources: [UUID: Set<UUID>] = [:]
    private var notedByTurn: [UUID: [UUID]] = [:]
    private(set) var turns: [Turn] = []
    private(set) var prompts: [Prompt] = []
    private(set) var facts: [TalkFact] = []
    private(set) var quickReplies: [String] = []
    private(set) var latestStoryDate: Date?
    // The newest message from Eira, so only that one plays its reveal.
    private(set) var latestReplyID: UUID?
    private(set) var isWorking = false
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        store = dependencies.store
        client = dependencies.serverClient
        dependencies.lifetime?.onLock { [weak self] in
            self?.active = false
            self?.turns = []
            self?.prompts = []
            self?.facts = []
            self?.quickReplies = []
            self?.replies = [:]
            self?.replySources = [:]
            self?.notedByTurn = [:]
            self?.latestStoryDate = nil
            self?.errorMessage = nil
        }
    }

    static func needsLawyerCaveat(_ response: AskResponse) -> Bool {
        !Set(response.faqAnswersUsed).isDisjoint(with: [4, 7, 11])
    }

    func prompts(after turn: UUID?) -> [Prompt] { prompts.filter { $0.afterTurn == turn } }

    func noted(for turn: UUID) -> [TalkFact] {
        let ids = notedByTurn[turn, default: []]
        return facts.filter { ids.contains($0.id) && !$0.value.isEmpty }
    }

    var hasNotedFacts: Bool { facts.contains { !$0.value.isEmpty } }
    var notedFactCount: Int { facts.filter { !$0.value.isEmpty }.count }

    // Skip is offered only while Eira's last message is an open question.
    var hasOpenQuestion: Bool {
        guard !isWorking else { return false }
        let last = turns.last
        let text = prompts(after: last?.id).last?.text ?? last?.response?.answer
        return text?.trimmingCharacters(in: .whitespaces).hasSuffix("?") == true
    }

    private func show(_ entries: [Entry], facts stored: [TalkFact]) {
        guard active else { return }
        let allowed = entries.filter { $0.allowedUses.legalGuidance }
        let allowedIDs = Set(allowed.map(\.id))
        for entry in entries where entry.kind == .question {
            guard let saved = entry.talkAnswer else { continue }
            replies[entry.id] = saved
            replySources[entry.id] = Set(entry.talkAnswerSources ?? [])
        }
        // A previous answer may contain a story whose permission has since changed.
        replies = replies.filter { replySources[$0.key, default: []].isSubset(of: allowedIDs) }
        prompts = prompts.filter { $0.sources.isSubset(of: allowedIDs) }
        // Keep restricted questions visible so she can restore their permissions.
        turns = entries.filter { $0.kind == .question }
            .sorted { $0.createdAt < $1.createdAt }
            .map { Turn(entry: $0, response: replies[$0.id]) }
        facts = TalkFacts.visible(stored, entries: entries)
        latestStoryDate = allowed.filter { $0.kind == .story }.map(\.createdAt).max()
    }

    func load() async {
        do { show(try await store.entries(), facts: try await store.talkFacts()) }
        catch { if active { errorMessage = "Your questions could not be opened. Try again." } }
    }

    // Asks the first question once. With nothing written yet, Eira waits for her.
    func start() async {
        guard active, !started else { return }
        started = true
        await load()
        guard latestStoryDate != nil || !turns.isEmpty else { return }
        await askNext(skipped: false)
    }

    func skip() async { await askNext(skipped: true) }

    func setUses(_ uses: AllowedUses, for id: UUID) async {
        guard active else { return }
        do {
            guard var entry = try await store.entries().first(where: { $0.id == id && $0.kind == .question }),
                  active else { return }
            entry.allowedUses = uses
            try await store.saveEntry(entry)
            await load()
        } catch { if active { errorMessage = "Your choices could not be saved. Try again." } }
    }

    func deleteQuestion(_ id: UUID) async {
        guard active, !isWorking else { return }
        do {
            try await store.deleteEntry(id: id)
            replies[id] = nil
            replySources[id] = nil
            prompts.removeAll { $0.afterTurn == id }
            await load()
        } catch { if active { errorMessage = "This question could not be deleted. Try again." } }
    }

    func send(_ text: String, source: EntrySource = .text) async -> Bool {
        await submit(Entry(text: text, source: source, kind: .question))
    }

    // A tapped reply is suggested wording, so it stays out of the report unless she allows it.
    func sendQuickReply(_ text: String) async -> Bool {
        var uses = EntryUseDefaults.allowedUses
        uses.report = false
        return await submit(Entry(text: text, source: .quickReply, kind: .question, allowedUses: uses))
    }

    private func submit(_ question: Entry) async -> Bool {
        guard active, !isWorking, !question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        isWorking = true
        errorMessage = nil
        quickReplies = []
        defer { isWorking = false }
        do {
            try await store.saveEntry(question)
            return await answer(question)
        } catch {
            guard active else { return false }
            errorMessage = "Your question could not be saved. Try again."
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

    private func conversation(before question: UUID?) -> [AskMessage] {
        var messages = prompts(after: nil).map { AskMessage(role: .assistant, text: $0.text) }
        for turn in turns {
            if turn.id == question { break }
            guard turn.entry.allowedUses.legalGuidance else { continue }
            messages.append(AskMessage(role: .user, text: turn.entry.text))
            if let response = turn.response { messages.append(AskMessage(role: .assistant, text: response.answer)) }
            messages += prompts(after: turn.id).map { AskMessage(role: .assistant, text: $0.text) }
        }
        return messages
    }

    private func saveNoted(_ incoming: [TalkFactResponse], sources: [Entry], turn: UUID?) async throws {
        guard !incoming.isEmpty else { return }
        let merged = TalkFacts.merged(incoming, into: try await store.talkFacts(), sources: sources)
        guard !merged.added.isEmpty, active else { return }
        try await store.saveTalkFacts(merged.all)
        if let turn { notedByTurn[turn, default: []] += merged.added }
    }

    private func askNext(skipped: Bool) async {
        guard active, !isWorking else { return }
        isWorking = true
        errorMessage = nil
        quickReplies = []
        defer { isWorking = false }
        do {
            let entries = try await store.entries()
            let stored = try await store.talkFacts()
            show(entries, facts: stored)
            let sources = entries.filter { $0.allowedUses.legalGuidance }
            let talk = try await client.talk(TalkRequest(message: nil, conversation: conversation(before: nil),
                entries: sources, events: try await store.events()))
            guard active, !Task.isCancelled else { return }
            let reply = talk.reply.trimmingCharacters(in: .whitespacesAndNewlines)
            let current = try await store.entries()
            guard active, !reply.isEmpty, !talk.isLegalQuestion else { return }
            let sourceIDs = Set(sources.map(\.id))
            guard sourceIDs.isSubset(of: Set(current.filter { $0.allowedUses.legalGuidance }.map(\.id))) else {
                show(current, facts: try await store.talkFacts())
                return
            }
            try await saveNoted(talk.facts, sources: current, turn: nil)
            let prompt = Prompt(text: reply, afterTurn: turns.last?.id, skipped: skipped, sources: sourceIDs)
            prompts.append(prompt)
            latestReplyID = prompt.id
            quickReplies = talk.quickReplies
            show(current, facts: try await store.talkFacts())
        } catch {
            if active { errorMessage = "The next question could not be loaded. You can still type." }
        }
    }

    private func answer(_ question: Entry) async -> Bool {
        do {
            let entries = try await store.entries()
            show(entries, facts: try await store.talkFacts())
            guard entries.contains(where: { $0.id == question.id && $0.allowedUses.legalGuidance }) else { return true }
            let messages = conversation(before: question.id)
            let sources = entries.filter { $0.allowedUses.legalGuidance }
            let context = sources.filter { $0.id != question.id }
            let events = try await store.events()
            let talk = try await client.talk(TalkRequest(message: question.text, conversation: messages,
                                                         entries: context, events: events))
            guard active, !Task.isCancelled else { return true }
            // Legal questions only ever use the Ask route and its approved FAQ.
            let response = talk.isLegalQuestion
                ? try await client.ask(AskRequest(question: question.text, conversation: messages,
                                                  entries: context, events: events))
                : AskResponse(answer: talk.reply, faqAnswersUsed: [], articlesNamed: [], notSure: false)
            guard active, !Task.isCancelled else { return true }
            let current = try await store.entries()
            guard active else { return true }
            let sourceIDs = Set(sources.map(\.id))
            let currentIDs = Set(current.filter { $0.allowedUses.legalGuidance }.map(\.id))
            if sourceIDs.isSubset(of: currentIDs) {
                replies[question.id] = response
                replySources[question.id] = sourceIDs
                latestReplyID = question.id
                if var saved = current.first(where: { $0.id == question.id }) {
                    saved.talkAnswer = response
                    saved.talkAnswerSources = Array(sourceIDs)
                    try await store.saveEntry(saved)
                }
                try await saveNoted(talk.facts, sources: current, turn: question.id)
                if !talk.isLegalQuestion { quickReplies = talk.quickReplies }
            }
            show(current, facts: try await store.talkFacts())
            return true
        } catch {
            guard active else { return true }
            errorMessage = "The answer could not be loaded. Your question is saved. You can try again."
            // The question was saved; clear the composer without creating a duplicate on retry.
            return true
        }
    }
}
