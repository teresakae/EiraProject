import XCTest
@testable import Eira

private actor TalkClient: ServerClient {
    var requests: [TalkRequest] = []
    var askCount = 0
    var response: TalkResponse
    init(_ response: TalkResponse) { self.response = response }
    func set(_ value: TalkResponse) { response = value }
    func talks() -> [TalkRequest] { requests }
    func asks() -> Int { askCount }
    func talk(_ request: TalkRequest) async throws -> TalkResponse { requests.append(request); return response }
    func ask(_ request: AskRequest) async throws -> AskResponse {
        askCount += 1
        return AskResponse(answer: "I cannot answer that yet.", faqAnswersUsed: [], articlesNamed: [], notSure: true)
    }
    func extract(_ request: ExtractRequest) async throws -> ExtractResponse { try await CannedServerClient().extract(request) }
    func draft(_ request: DraftRequest) async throws -> DraftResponse { try await CannedServerClient().draft(request) }
    func transcribe(_ request: TranscribeRequest) async throws -> String { "" }
}

@MainActor
final class TalkSummaryTests: XCTestCase {
    private func reply(_ text: String = "Has this happened before?", legal: Bool = false,
                       chips: [String] = [], facts: [TalkFactResponse] = []) -> TalkResponse {
        TalkResponse(reply: text, isLegalQuestion: legal, quickReplies: chips, facts: facts)
    }

    func testFactFailingTheQuoteCheckIsDropped() async throws {
        let store = InMemoryEiraStore()
        let client = TalkClient(reply(facts: [
            .init(category: .who, value: "your supervisor", quote: "atasanku"),
            .init(category: .where, value: "invented place", quote: "di tempat karangan"),
        ]))
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        _ = await flow.send("Dia atasanku di kantor.")
        XCTAssertEqual(flow.facts.map(\.value), ["your supervisor"])
        let id = try XCTUnwrap(flow.turns.last?.id)
        XCTAssertEqual(flow.noted(for: id).map(\.value), ["your supervisor"])
    }

    func testTappedQuickReplyIsNeverAQuoteSourceAndStaysOutOfTheReport() async throws {
        let store = InMemoryEiraStore()
        let client = TalkClient(reply(facts: [.init(category: .who, value: "invented", quote: "Yes, my boss")]))
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        _ = await flow.sendQuickReply("Yes, my boss")
        XCTAssertTrue(flow.facts.isEmpty)
        let all = try await store.entries()
        let saved = try XCTUnwrap(all.last)
        XCTAssertEqual(saved.source, .quickReply)
        XCTAssertFalse(saved.allowedUses.report)
        XCTAssertTrue(DraftRequest(entries: [saved]).questions.isEmpty)
    }

    func testLegalQuestionUsesAskRouteAndNotTheTalkReply() async throws {
        let client = TalkClient(reply("Pasal karangan", legal: true))
        let flow = AskFlow(dependencies: .init(store: InMemoryEiraStore(), serverClient: client))
        _ = await flow.send("Will he go to jail?")
        let asks = await client.asks()
        XCTAssertEqual(asks, 1)
        XCTAssertEqual(flow.turns.last?.response?.answer, "I cannot answer that yet.")
    }

    func testLimitedEntriesAreNeverSentToTalkAndHideTheirFacts() async throws {
        let store = InMemoryEiraStore()
        let hidden = Entry(text: "Cerita rahasia buatan.", allowedUses: .init(personalTimeline: true, legalGuidance: false, report: true))
        try await store.saveEntry(hidden)
        try await store.saveTalkFacts([TalkFact(category: .what, value: "secret", quote: "rahasia", sourceEntryID: hidden.id)])
        let client = TalkClient(reply())
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        _ = await flow.send("Aku mau cerita.")
        let talks = await client.talks()
        let request = try XCTUnwrap(talks.last)
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(request), as: UTF8.self).contains("rahasia"))
        XCTAssertTrue(flow.facts.isEmpty)
    }

    func testOpeningAndSkipSendExplicitNullWithoutSavingAnEntry() async throws {
        let store = InMemoryEiraStore()
        try await store.saveEntry(Entry(text: "Cerita buatan."))
        let client = TalkClient(reply("Where were you?", chips: ["At home"]))
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        await flow.start()
        await flow.start()
        XCTAssertEqual(flow.prompts.count, 1, "The opening question is asked once")
        XCTAssertTrue(flow.hasOpenQuestion)
        XCTAssertEqual(flow.quickReplies, ["At home"])
        await flow.skip()
        XCTAssertEqual(flow.prompts.count, 2)
        XCTAssertTrue(flow.prompts[1].skipped)
        let saved = try await store.entries()
        XCTAssertEqual(saved.count, 1)
        let talks = await client.talks()
        let wire = try JSONSerialization.jsonObject(with: JSONEncoder().encode(XCTUnwrap(talks.last))) as? [String: Any]
        XCTAssertTrue(wire?["message"] is NSNull)
        XCTAssertEqual((wire?["conversation"] as? [Any])?.count, 1, "Earlier questions go back so none repeats")
    }

    func testNoStoryMeansNoOpeningCall() async {
        let client = TalkClient(reply())
        let flow = AskFlow(dependencies: .init(store: InMemoryEiraStore(), serverClient: client))
        await flow.start()
        let talks = await client.talks()
        XCTAssertTrue(talks.isEmpty)
        XCTAssertEqual(SafetyStrings.talkOpening(entryDate: nil), SafetyStrings.talkNoStory)
    }

    func testFixWinsOverLaterAIFactsReachesTheDraftAndSurvivesReopening() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = EncryptedEiraStore(directory: directory)
        defer { try? store.deleteSecretData(); try? FileManager.default.removeItem(at: directory) }
        try store.open()
        let session = PrivateSessionStore(store)
        let dependencies = AppDependencies(store: session, serverClient: TalkClient(reply()))
        let ask = AskFlow(dependencies: dependencies)
        _ = await ask.send("Dia atasanku di kantor.")
        let summary = SummaryFlow(dependencies: dependencies)
        let fixed = await summary.fix(.who, text: "My husband")
        XCTAssertTrue(fixed)
        XCTAssertTrue(summary.isEdited(.who))

        let incoming = TalkFacts.merged([.init(category: .who, value: "your supervisor", quote: "atasanku")],
                                        into: try await session.talkFacts(), sources: try await session.entries())
        XCTAssertTrue(incoming.added.isEmpty, "A later AI fact cannot replace her fix")

        let draft = DraftRequest(entries: try await session.entries())
        XCTAssertTrue(draft.questions.contains("Person: My husband"))
        XCTAssertFalse(draft.entries.contains("Person: My husband"))
        let story = WriteFlow(dependencies: dependencies)
        await story.load()
        XCTAssertTrue(story.entries.isEmpty, "A fix never shows as a diary entry")

        let again = await summary.fix(.who, text: "My husband, Budi")
        XCTAssertTrue(again)
        let corrections = try await session.entries().filter { $0.kind == .correction }
        XCTAssertEqual(corrections.map(\.text), ["Person: My husband, Budi"], "A new fix replaces the old one")

        store.lock()
        try store.open()
        let reopened = SummaryFlow(dependencies: .init(store: PrivateSessionStore(store)))
        await reopened.load()
        XCTAssertEqual(reopened.value(for: .who), "My husband, Budi")

        let cleared = await reopened.fix(.who, text: " ")
        XCTAssertTrue(cleared)
        XCTAssertEqual(reopened.value(for: .who), "")
        try store.deleteSecretData()
        try store.open()
        XCTAssertTrue(try store.talkFacts().isEmpty, "Delete everything removes noted facts")
    }

    func testLegalReferencesAreFixedAndSkipUnsureAndLimitedEntries() {
        let allowed = Entry(text: "Cerita buatan.")
        let limited = Entry(text: "Cerita lain.", allowedUses: .init(personalTimeline: true, legalGuidance: false, report: true))
        let event = { (entry: Entry, type: ViolenceType) in
            Event(entryID: entry.id, whenText: nil, whatHappened: "x", injuries: nil, witnesses: [], quote: "x", violenceType: type)
        }
        let references = LegalReferences.references(entries: [allowed, limited], events: [
            event(allowed, .physical), event(allowed, .physical), event(allowed, .unsure), event(limited, .sexual),
        ])
        XCTAssertEqual(references.map(\.article), ["Pasal 6"])
        XCTAssertEqual(references.first?.reason, "You mentioned an incident involving unwanted physical contact.")
        XCTAssertEqual(SafetyStrings.legalHeading, "POSSIBLY RELEVANT LEGAL REFERENCES")
        XCTAssertEqual(SafetyStrings.legalBecause, "This may be relevant because")
        let copy = [SafetyStrings.legalFootnote, SafetyStrings.legalConsequence, SafetyStrings.talkAskFirst, SafetyStrings.talkNoStory]
            .joined(separator: " ").lowercased()
        for banned in ["lawyer-checked", "keeps you safe", "committed", "you should report", "your report"] {
            XCTAssertFalse(copy.contains(banned))
        }
    }

    func testRewordedFactFromSameQuoteIsNotAddedTwice() {
        let entry = Entry(text: "Tadi malam suami saya, Rudi, mendorong saya.", kind: .story)
        let first = TalkFacts.merged([.init(category: .when, value: "last night", quote: "Tadi malam")],
                                     into: [], sources: [entry])
        let second = TalkFacts.merged([.init(category: .when, value: "Tadi malam", quote: "Tadi malam"),
                                       .init(category: .what, value: "Rudi pushed you", quote: "mendorong saya")],
                                      into: first.all, sources: [entry])
        XCTAssertEqual(second.added.count, 1)
        XCTAssertEqual(second.all.map(\.value), ["last night", "Rudi pushed you"])
    }
}
