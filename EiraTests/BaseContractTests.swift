import XCTest
@testable import Eira

final class BaseContractTests: XCTestCase {
    func testCannedExtractionMatchesWireContractAndOnlyUsesFixture() async throws {
        let client = CannedServerClient()
        let response = try await client.extract(ExtractRequest(text: CannedServerClient.sampleEntryText))
        XCTAssertEqual(response.events.count, 1)
        XCTAssertFalse(response.reply.isEmpty)
        XCTAssertFalse(response.coverTask.isEmpty)
        XCTAssertNotEqual(response.coverTask, "eira")
        let entry = Entry(text: CannedServerClient.sampleEntryText)
        XCTAssertNotNil(response.events.first?.event(for: entry))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["events", "cover_task", "reply"])
        let events = try XCTUnwrap(json["events"] as? [[String: Any]])
        XCTAssertTrue(events[0]["injuries"] is String)
        XCTAssertNil(events[0]["entry_id"])
        let unrelated = try await client.extract(ExtractRequest(text: "Catatan contoh lain."))
        XCTAssertTrue(unrelated.events.isEmpty)
    }

    func testCannedAskHandsOffWithoutLegalClaims() async throws {
        let response = try await CannedServerClient().ask(AskRequest(question: "Apa pilihanku?", conversation: [], entries: [], events: []))
        XCTAssertTrue(response.notSure)
        XCTAssertTrue(response.faqAnswersUsed.isEmpty)
        XCTAssertTrue(response.articlesNamed.isEmpty)
        XCTAssertTrue(response.answer.contains("belum bisa"))
        XCTAssertTrue(response.answer.contains("LBH APIK"))
        XCTAssertEqual(try JSONDecoder().decode(AskResponse.self, from: JSONEncoder().encode(response)), response)
    }

    func testRequestsExcludeEntriesNotAllowedForTheirUse() throws {
        let hidden = Entry(text: "Tidak untuk AI tahap berikutnya.", allowedUses: AllowedUses(personalTimeline: true, legalGuidance: false, report: false))
        let story = Entry(text: "Cerita contoh.")
        let question = Entry(text: "Pertanyaan contoh.", kind: .question)
        let event = Event(entryID: hidden.id, whenText: nil, whatHappened: hidden.text,
                          injuries: nil, witnesses: [], quote: hidden.text, violenceType: .unsure)
        let ask = AskRequest(question: "Apa pilihanku?", conversation: [], entries: [hidden, story], events: [event])
        XCTAssertEqual(ask.entries.map(\.text), [story.text])
        XCTAssertTrue(ask.entries[0].events.isEmpty)
        let draft = DraftRequest(entries: [hidden, story, question])
        XCTAssertEqual(draft.entries, [story.text])
        XCTAssertEqual(draft.questions, [question.text])
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(draft), as: UTF8.self).contains(hidden.text))
    }

    func testDraftHasAllSeventeenPairsWithExplicitNulls() async throws {
        let client = CannedServerClient()
        let empty = try await client.draft(DraftRequest(entries: []))
        let data = try JSONEncoder().encode(empty)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: [String: Any]])
        XCTAssertEqual(Set(json.keys), Set(ReportFieldName.allCases.map(\.rawValue)))
        XCTAssertEqual(json.count, 17)
        for pair in json.values {
            XCTAssertEqual(Set(pair.keys), ["value", "quote"])
            XCTAssertTrue(pair["value"] is NSNull)
            XCTAssertTrue(pair["quote"] is NSNull)
        }
        XCTAssertEqual(try JSONDecoder().decode(DraftResponse.self, from: data), empty)
        let populated = try await client.draft(DraftRequest(entries: [Entry(text: CannedServerClient.sampleEntryText)]))
        XCTAssertEqual(populated.fields[.description]?.quote, CannedServerClient.sampleEntryText)
        XCTAssertNil(populated.fields[.levelConcern]?.value)
    }

    func testTypedValuesAndTranscriptionStandIn() async throws {
        for value in [ReportValue.text("contoh"), .integer(32), .boolean(false)] {
            XCTAssertEqual(try JSONDecoder().decode(ReportValue.self, from: JSONEncoder().encode(value)), value)
        }
        let request = TranscribeRequest(audio: Data(), filename: "sample.m4a", contentType: "audio/mp4")
        XCTAssertEqual(request.language, "id")
        let transcript = try await CannedServerClient().transcribe(request)
        XCTAssertEqual(transcript, CannedServerClient.sampleEntryText)
    }

    @MainActor
    func testStoreUpsertAndSecretDeletionPreserveCoverTasks() async throws {
        let store: any EiraStore = InMemoryEiraStore()
        var entry = Entry(text: "Catatan buatan.")
        try await store.saveEntry(entry)
        entry.allowedUses.report = false
        try await store.saveEntry(entry)
        let entries = try await store.entries()
        XCTAssertEqual(entries, [entry])
        let task = CoverTask(title: "Rapikan meja")
        try await store.saveCoverTask(task)
        try await store.saveReportDraft(ReportDraft())
        let event = Event(entryID: entry.id, whenText: nil, whatHappened: entry.text,
                          injuries: nil, witnesses: [], quote: entry.text, violenceType: .unsure)
        try await store.saveEvents([event], for: entry.id)
        try await store.deleteSecretData()
        let remainingEntries = try await store.entries()
        let remainingEvents = try await store.events()
        let remainingDraft = try await store.reportDraft()
        let remainingTasks = try await store.coverTasks()
        XCTAssertTrue(remainingEntries.isEmpty)
        XCTAssertTrue(remainingEvents.isEmpty)
        XCTAssertNil(remainingDraft)
        XCTAssertEqual(remainingTasks, [task])
    }

    func testDefaultUsesAndReportTargetMatchConfiguration() {
        XCTAssertEqual(Entry(text: "Contoh.").allowedUses,
                       AllowedUses(personalTimeline: true, legalGuidance: true, report: true))
        let configured = Bundle.main.object(forInfoDictionaryKey: "EiraReportTarget") as? String
        XCTAssertNotNil(configured.flatMap(ReportTarget.init(rawValue:)))
        #if DEBUG
        XCTAssertEqual(ReportTarget.current, .mock)
        #else
        XCTAssertEqual(ReportTarget.current.rawValue, configured)
        #endif
    }
}
