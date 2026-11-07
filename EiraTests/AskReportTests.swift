import XCTest
import SwiftUI
import WebKit
@testable import Eira

actor RecordingReportClient: ServerClient {
    var askRequests: [AskRequest] = []
    var draftRequests: [DraftRequest] = []
    let askResponse: AskResponse
    let draftResponse: DraftResponse?
    var fails = false
    var holdDraft = false
    var draftContinuation: CheckedContinuation<Void, Never>?

    init(faq: [Int] = [], draft: DraftResponse? = nil) {
        askResponse = AskResponse(answer: "Jawaban contoh untuk pengujian, bukan informasi hukum.",
                                  faqAnswersUsed: faq, articlesNamed: [], notSure: true)
        draftResponse = draft
    }

    func setFailure(_ value: Bool) { fails = value }
    func pauseDraft() { holdDraft = true }
    func resumeDraft() { draftContinuation?.resume(); draftContinuation = nil; holdDraft = false }
    func asks() -> [AskRequest] { askRequests }
    func drafts() -> [DraftRequest] { draftRequests }

    func ask(_ request: AskRequest) async throws -> AskResponse {
        askRequests.append(request)
        if fails { throw URLError(.notConnectedToInternet) }
        return askResponse
    }

    func draft(_ request: DraftRequest) async throws -> DraftResponse {
        draftRequests.append(request)
        if holdDraft { await withCheckedContinuation { draftContinuation = $0 } }
        if fails { throw URLError(.notConnectedToInternet) }
        if let draftResponse { return draftResponse }
        return try await CannedServerClient().draft(request)
    }

    func extract(_ request: ExtractRequest) async throws -> ExtractResponse { try await CannedServerClient().extract(request) }
    func transcribe(_ request: TranscribeRequest) async throws -> String { try await CannedServerClient().transcribe(request) }
}

@MainActor
final class AskReportTests: XCTestCase {
    func testU2FiltersStoriesQuestionsEventsAndOldAssistantContext() async throws {
        let store = InMemoryEiraStore()
        let client = RecordingReportClient(faq: [4])
        var allowed = Entry(text: CannedServerClient.sampleEntryText)
        let hidden = Entry(text: "Cerita buatan yang dibatasi.", allowedUses: .init(personalTimeline: true, legalGuidance: false, report: true))
        let hiddenQuestion = Entry(text: "Pertanyaan buatan yang dibatasi.", kind: .question, allowedUses: hidden.allowedUses)
        for entry in [allowed, hidden, hiddenQuestion] { try await store.saveEntry(entry) }
        try await store.saveEvents([Event(entryID: hidden.id, whenText: nil, whatHappened: hidden.text,
            injuries: nil, witnesses: [], quote: hidden.text, violenceType: .unsure)], for: hidden.id)
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        let question = "Apa pilihanku?"
        let sent = await flow.send(question)
        XCTAssertTrue(sent)
        let requests = await client.asks()
        XCTAssertEqual(requests[0].entries.map(\.text), [allowed.text])
        XCTAssertTrue(requests[0].entries.allSatisfy { $0.events.isEmpty })
        XCTAssertTrue(requests[0].conversation.isEmpty)
        XCTAssertEqual(flow.turns.map(\.entry.text), [hiddenQuestion.text, question])
        XCTAssertNil(flow.turns.first?.response)
        XCTAssertNotNil(flow.turns.last?.response)
        let saved = try await store.entries()
        XCTAssertEqual(saved.last?.kind, .question)
        XCTAssertEqual(saved.last?.text, question)
        let events = try await store.events()
        XCTAssertTrue(events.allSatisfy { $0.entryID != saved.last?.id })

        allowed.allowedUses.legalGuidance = false
        try await store.saveEntry(allowed)
        await flow.load()
        XCTAssertTrue(flow.turns.allSatisfy { $0.response == nil })
        _ = await flow.send("Bisa jelaskan lagi?")
        let asks = await client.asks()
        let followup = try XCTUnwrap(asks.last)
        XCTAssertFalse(followup.conversation.contains { $0.role == .assistant })
        let wire = String(decoding: try JSONEncoder().encode(followup), as: UTF8.self)
        for excluded in [hidden.text, hiddenQuestion.text, allowed.text] { XCTAssertFalse(wire.contains(excluded)) }
    }

    func testQuestionPermissionsPersistAndFilterDraftsConversationAndRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = EncryptedEiraStore(directory: directory)
        defer { try? store.deleteSecretData(); try? FileManager.default.removeItem(at: directory) }
        try store.open()
        let text = "Aku tinggal di Kota Bekasi, Jawa Barat. Apa pilihanku?"
        let client = RecordingReportClient(faq: [4], draft: .init(fields: [
            .provinceCity: .init(value: .text("Kota Bekasi, Jawa Barat"), quote: "Kota Bekasi, Jawa Barat")]))
        let dependencies = AppDependencies(store: PrivateSessionStore(store), serverClient: client)
        let ask = AskFlow(dependencies: dependencies)
        _ = await ask.send(text)
        let id = try XCTUnwrap(ask.turns.first?.id)
        let report = ReportFlow(dependencies: dependencies)
        await report.refresh()
        XCTAssertEqual(report.draft.fields.first { $0.fieldName == .provinceCity }?.sourceEntryID, id)
        let uses = AllowedUses(personalTimeline: true, legalGuidance: false, report: false)
        await ask.setUses(uses, for: id)
        XCTAssertEqual(ask.turns.first?.entry.allowedUses, uses)
        XCTAssertNil(ask.turns.first?.response)
        await report.load()
        XCTAssertNil(report.draft.fields.first { $0.fieldName == .provinceCity }?.value)
        await report.refresh()
        let drafts = await client.drafts()
        XCTAssertTrue(try XCTUnwrap(drafts.last).questions.isEmpty)
        let beforeRetry = await client.asks().count
        await ask.retry(try XCTUnwrap(ask.turns.first?.entry))
        let afterRetry = await client.asks().count
        XCTAssertEqual(beforeRetry, afterRetry)
        _ = await ask.send("Bisa jelaskan pilihanku?")
        let requests = await client.asks()
        let wire = String(decoding: try JSONEncoder().encode(XCTUnwrap(requests.last)), as: UTF8.self)
        XCTAssertFalse(wire.contains(text))
        XCTAssertFalse(try XCTUnwrap(requests.last).conversation.contains { $0.role == .assistant })
        store.lock()
        try store.open()
        let reopened = AskFlow(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
        await reopened.load()
        XCTAssertEqual(reopened.turns.first { $0.id == id }?.entry.allowedUses, uses)
        XCTAssertNotNil(reopened.turns.first { $0.id == id })
        await reopened.setUses(.init(personalTimeline: true, legalGuidance: true, report: true), for: id)
        XCTAssertTrue(try XCTUnwrap(store.entries().first { $0.id == id }).allowedUses.report)
        await reopened.retry(try XCTUnwrap(reopened.turns.first { $0.id == id }?.entry))
        XCTAssertNotNil(reopened.turns.first { $0.id == id }?.response)
    }

    func testV1CaveatIsControlledByReturnedFAQNumbers() {
        for faq in [[4], [7], [11], [1, 11], [4, 7, 11]] {
            let reply = AskResponse(answer: "Contoh uji.", faqAnswersUsed: faq, articlesNamed: [], notSure: false)
            XCTAssertTrue(AskFlow.needsLawyerCaveat(reply))
        }
        for faq in [[], [1, 2, 3], [14]] as [[Int]] {
            XCTAssertFalse(AskFlow.needsLawyerCaveat(.init(answer: "Contoh uji.", faqAnswersUsed: faq, articlesNamed: [], notSure: true)))
        }
        XCTAssertTrue(SafetyStrings.lawyerCaveat.contains("not been reviewed"))
    }

    func testCannedHandoffAppearsAsReplyAndFailureRetriesWithoutDuplicatingQuestion() async throws {
        let store = InMemoryEiraStore()
        let canned = AskFlow(dependencies: .init(store: store))
        _ = await canned.send("Apa pilihanku?")
        XCTAssertTrue(canned.turns.first?.response?.answer.contains("cannot answer") == true)
        XCTAssertTrue(canned.turns.first?.response?.answer.contains("LBH APIK") == true)
        let client = RecordingReportClient()
        await client.setFailure(true)
        let flow = AskFlow(dependencies: .init(store: store, serverClient: client))
        _ = await flow.send("Pertanyaan uji kedua.")
        XCTAssertNotNil(flow.errorMessage)
        let question = try XCTUnwrap(flow.turns.last?.entry)
        let before = try await store.entries().count
        await client.setFailure(false)
        await flow.retry(question)
        let after = try await store.entries().count
        XCTAssertEqual(before, after)
        XCTAssertNotNil(flow.turns.last?.response)
        XCTAssertNil(flow.errorMessage)
    }

    func testU1FiltersDraftRequestAndRechecksExistingDraftAfterPermissionChange() async throws {
        let store = InMemoryEiraStore()
        let client = RecordingReportClient()
        var entry = Entry(text: CannedServerClient.sampleEntryText)
        let question = Entry(text: "Aku tinggal di Kota Bekasi, Jawa Barat.", kind: .question)
        try await store.saveEntry(entry)
        try await store.saveEntry(question)
        let flow = ReportFlow(dependencies: .init(store: store, serverClient: client))
        await flow.refresh()
        XCTAssertEqual(flow.draft.fields.first { $0.fieldName == .description }?.value, .text(entry.text))
        entry.allowedUses.report = false
        try await store.saveEntry(entry)
        await flow.load()
        XCTAssertNil(flow.draft.fields.first { $0.fieldName == .description }?.value)
        await flow.refresh()
        let drafts = await client.drafts()
        let request = try XCTUnwrap(drafts.last)
        XCTAssertTrue(request.entries.isEmpty)
        XCTAssertEqual(request.questions, [question.text])
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(request), as: UTF8.self).contains(entry.text))
        let copied = await flow.copyText(for: .description)
        XCTAssertNil(copied)
    }

    func testAnswersSurviveLeavingTalkAndGoWithTheirSources() async throws {
        let store = InMemoryEiraStore()
        let story = Entry(text: CannedServerClient.sampleEntryText)
        try await store.saveEntry(story)
        let first = AskFlow(dependencies: .init(store: store))
        let sent = await first.send("Will he be arrested?")
        XCTAssertTrue(sent)
        let answer = try XCTUnwrap(first.turns.first?.response)

        let reopened = AskFlow(dependencies: .init(store: store))
        await reopened.load()
        XCTAssertEqual(reopened.turns.first?.response, answer)

        var limited = story
        limited.allowedUses.legalGuidance = false
        try await store.saveEntry(limited)
        await reopened.load()
        XCTAssertNil(reopened.turns.first?.response, "Hidden while its source is limited")
        try await store.saveEntry(story)
        await reopened.load()
        XCTAssertEqual(reopened.turns.first?.response, answer, "Back when the permission returns")

        try await store.deleteEntry(id: story.id)
        let saved = try await store.entries().first { $0.kind == .question }
        XCTAssertNil(saved?.talkAnswer, "Deleting a source deletes the answer drawn from it")

        let id = try XCTUnwrap(reopened.turns.first?.id)
        await reopened.deleteQuestion(id)
        XCTAssertTrue(reopened.turns.isEmpty)
    }

    func testEmptyDraftFillsOnOpenOnlyOnceAndNeverSendsLimitedEntries() async throws {
        let store = InMemoryEiraStore()
        let client = RecordingReportClient()
        var entry = Entry(text: CannedServerClient.sampleEntryText)
        entry.allowedUses.report = false
        try await store.saveEntry(entry)
        let flow = ReportFlow(dependencies: .init(store: store, serverClient: client))
        await flow.load()
        await flow.fillIfEmpty()
        var drafts = await client.drafts()
        XCTAssertTrue(drafts.isEmpty, "Nothing allowed for the report, so nothing is sent")

        entry.allowedUses.report = true
        try await store.saveEntry(entry)
        await flow.fillIfEmpty()
        drafts = await client.drafts()
        XCTAssertEqual(drafts.count, 1)
        XCTAssertNotNil(flow.draft.fields.first { $0.fieldName == .description }?.value)

        await flow.fillIfEmpty()
        drafts = await client.drafts()
        XCTAssertEqual(drafts.count, 1, "A filled draft is not rebuilt on open")
    }

    func testClearingEveryFieldDoesNotRefillOnOpen() async throws {
        let store = InMemoryEiraStore()
        let client = RecordingReportClient()
        try await store.saveEntry(Entry(text: CannedServerClient.sampleEntryText))
        let flow = ReportFlow(dependencies: .init(store: store, serverClient: client))
        await flow.refresh()
        for field in flow.draft.fields where field.value != nil {
            let cleared = await flow.edit(field.fieldName, text: "")
            XCTAssertTrue(cleared)
        }
        await flow.fillIfEmpty()
        let drafts = await client.drafts()
        XCTAssertEqual(drafts.count, 1)
    }

    func testEditsIncludingClearsSurviveRefreshAndReopening() async throws {
        let store = InMemoryEiraStore()
        try await store.saveEntry(Entry(text: CannedServerClient.sampleEntryText))
        let flow = ReportFlow(dependencies: .init(store: store))
        await flow.refresh()
        let editedCity = await flow.edit(.provinceCity, text: "Kota Bekasi, Jawa Barat")
        let clearedDescription = await flow.edit(.description, text: "")
        XCTAssertTrue(editedCity)
        XCTAssertTrue(clearedDescription)
        await flow.refresh()
        let reopened = ReportFlow(dependencies: .init(store: store))
        await reopened.load()
        let edited = try XCTUnwrap(reopened.draft.fields.first { $0.fieldName == .provinceCity })
        XCTAssertEqual(edited.status, .editedByHer)
        XCTAssertNil(edited.quote)
        XCTAssertNil(edited.sourceEntryID)
        XCTAssertEqual(edited.value, .text("Kota Bekasi, Jawa Barat"))
        let cleared = try XCTUnwrap(reopened.draft.fields.first { $0.fieldName == .description })
        XCTAssertNil(cleared.value)
        XCTAssertEqual(cleared.status, .editedByHer)
        XCTAssertTrue(ReportFields.missingRequired(in: reopened.draft).contains(.description))
        let copied = await reopened.copyText(for: .provinceCity)
        let invalidAge = await reopened.edit(.victimAge, text: "101")
        let invalidPhone = await reopened.edit(.contactNumber, text: "+62")
        XCTAssertEqual(copied, "Kota Bekasi, Jawa Barat")
        XCTAssertFalse(invalidAge)
        XCTAssertFalse(invalidPhone)
    }

    func testRefreshRechecksPermissionsAndPreservesEditsMadeDuringRequest() async throws {
        let store = InMemoryEiraStore()
        var entry = Entry(text: CannedServerClient.sampleEntryText)
        try await store.saveEntry(entry)
        let client = RecordingReportClient()
        await client.pauseDraft()
        let flow = ReportFlow(dependencies: .init(store: store, serverClient: client))
        let refresh = Task { await flow.refresh() }
        while await client.drafts().isEmpty { await Task.yield() }
        entry.allowedUses.report = false
        try await store.saveEntry(entry)
        let edited = await flow.edit(.provinceCity, text: "Kota Bekasi, Jawa Barat")
        XCTAssertTrue(edited)
        await client.resumeDraft()
        await refresh.value
        XCTAssertNil(flow.draft.fields.first { $0.fieldName == .description }?.value)
        XCTAssertEqual(flow.draft.fields.first { $0.fieldName == .provinceCity }?.status, .editedByHer)
    }

    func testQ1Q4Q5AndEveryFieldRunsQuoteCheck() async throws {
        let entry = Entry(text: CannedServerClient.sampleEntryText)
        for _ in 0..<5 {
            let invented = DraftResponse(fields: [.victimFullName: .init(value: .text("Nama Rekaan"), quote: "Nama Rekaan")])
            let checked = ReportFields.merged(invented, keeping: .init(), entries: [entry])
            XCTAssertNil(checked.fields.first { $0.fieldName == .victimFullName }?.value)
        }
        for name in ReportFieldName.allCases {
            let value: ReportValue = ReportFields.isBoolean(name) ? .boolean(false) : name == .victimAge
                ? .integer(32) : .text(ReportFields.options(for: name)?.first ?? "Contoh")
            let checked = ReportFields.checked(.init(fields: [.init(fieldName: name, value: value, quote: "Sumber rekaan yang tidak ada.")]), entries: [entry])
            XCTAssertNil(checked.fields.first { $0.fieldName == name }?.value, name.rawValue)
        }
        let response = try await CannedServerClient().draft(.init(entries: [entry]))
        let draft = ReportFields.merged(response, keeping: .init(), entries: [entry])
        XCTAssertNil(draft.fields.first { $0.fieldName == .levelConcern }?.value)
        XCTAssertNil(draft.fields.first { $0.fieldName == .victimFullName }?.value)
        XCTAssertEqual(draft.fields.first { $0.fieldName == .description }?.sourceEntryID, entry.id)
        XCTAssertTrue(ReportFields.valid(.text("Tidak Diketahui"), for: .incidentTime))
        XCTAssertFalse(ReportFields.valid(.text("Subuh"), for: .incidentTime))
        XCTAssertFalse(ReportFields.valid(.text("32"), for: .victimAge))
        XCTAssertFalse(ReportFields.valid(.boolean(true), for: .victimGender))
        XCTAssertFalse(ReportFields.valid(.text(String(repeating: "a", count: 5001)), for: .description))
        XCTAssertFalse(ReportFields.valid(.text("１２３"), for: .contactNumber))
        let m1 = Entry(text: "Semalam sekitar jam 11 suamiku pulang mabuk, marah gara-gara nasi belum matang. Dia nampar pipi kiriku dua kali terus ndorong aku sampe kepala kebentur lemari. Pipiku masih bengkak. Anak-anak di kamar, yang gede (Dimas, 9 th) lihat dari pintu. Minggu lalu dia juga bilang aku \"gak berguna, mending mati aja\". Bulan ini dia belum kasih uang belanja sama sekali.")
        let m1Response = try await CannedServerClient().draft(.init(entries: [m1]))
        XCTAssertNil(m1Response.fields[.levelConcern]?.value)
        XCTAssertNil(m1Response.fields[.victimFullName]?.value)
    }

    func testConditionalRequiredFieldsAndFalseAreNotConfusedWithEmpty() {
        var draft = ReportDraft(fields: [
            .init(fieldName: .anonymous, value: .boolean(true), status: .editedByHer),
            .init(fieldName: .victimDisabilities, value: .boolean(false), status: .editedByHer)])
        var missing = ReportFields.missingRequired(in: draft)
        XCTAssertFalse(missing.contains(.reporterFullName))
        XCTAssertFalse(missing.contains(.victimDisabilities))
        XCTAssertFalse(missing.contains(.victimDisabilitiesType))
        draft.fields[0].value = .boolean(false)
        draft.fields[1].value = .boolean(true)
        missing = ReportFields.missingRequired(in: draft)
        XCTAssertTrue(missing.contains(.reporterFullName))
        XCTAssertTrue(missing.contains(.victimDisabilitiesType))
    }

    func testCF1ConfirmationGatesFormAndPermissionChangeInvalidatesConfirmation() async throws {
        let store = InMemoryEiraStore()
        var entry = Entry(text: CannedServerClient.sampleEntryText)
        try await store.saveEntry(entry)
        let flow = ReportFlow(dependencies: .init(store: store))
        await flow.refresh()
        await flow.openConfirmedForm()
        XCTAssertEqual(flow.stage, .review)
        XCTAssertNil(flow.deliveryDraft)
        await flow.prepareConfirmation()
        XCTAssertEqual(flow.stage, .confirmation)
        XCTAssertEqual(flow.deliveryDraft, flow.draft)
        entry.allowedUses.report = false
        try await store.saveEntry(entry)
        await flow.openConfirmedForm()
        XCTAssertEqual(flow.stage, .review)
        XCTAssertNil(flow.deliveryDraft)
        await flow.prepareConfirmation()
        await flow.openConfirmedForm()
        XCTAssertEqual(flow.stage, .form)
        XCTAssertNil(flow.deliveryDraft?.fields.first { $0.fieldName == .description }?.value)
        flow.closeDelivery()
        XCTAssertNil(flow.deliveryDraft)
        for text in [SafetyStrings.recipient, SafetyStrings.unknowns, SafetyStrings.risks, SafetyStrings.anonymity] {
            XCTAssertFalse(text.isEmpty)
        }
    }

    func testAfterSendAppearsOnlyAfterFormAndNotYetReturnsToReview() async throws {
        let store = InMemoryEiraStore()
        try await store.saveEntry(Entry(text: CannedServerClient.sampleEntryText))
        let flow = ReportFlow(dependencies: .init(store: store))
        await flow.refresh()
        flow.finishForm()
        XCTAssertEqual(flow.stage, .review)
        await flow.prepareConfirmation()
        flow.finishForm()
        XCTAssertEqual(flow.stage, .confirmation)
        await flow.openConfirmedForm()
        flow.finishForm()
        XCTAssertEqual(flow.stage, .afterSend)
        await flow.prepareConfirmation()
        XCTAssertEqual(flow.stage, .confirmation)
        XCTAssertNotNil(flow.deliveryDraft)
    }

    func testEditFromReviewUpdatesWhatTheFormReceives() async throws {
        let flow = ReportFlow(dependencies: .init(store: InMemoryEiraStore()))
        await flow.prepareConfirmation()
        let edited = await flow.edit(.provinceCity, text: "Kota Bekasi, Jawa Barat")
        XCTAssertTrue(edited)
        await flow.openConfirmedForm()
        XCTAssertEqual(flow.stage, .form)
        XCTAssertEqual(flow.formDraft?.fields.first { $0.fieldName == .provinceCity }?.value, .text("Kota Bekasi, Jawa Barat"))
    }

    func testContactLineIsVisibleInFormDraftAndNeverSavedOrOverLimit() async throws {
        let store = InMemoryEiraStore()
        let flow = ReportFlow(dependencies: .init(store: store))
        _ = await flow.edit(.description, text: "Catatan buatan.")
        await flow.prepareConfirmation()
        let description = { flow.formDraft?.fields.first { $0.fieldName == .description }?.value }
        // Nothing is added until she chooses.
        XCTAssertEqual(flow.contactPreference, .noPreference)
        XCTAssertEqual(description(), .text("Catatan buatan."))
        for preference in [ReportFlow.ContactPreference.noWhatsApp, .whatsAppOK] {
            flow.contactPreference = preference
            let line = try XCTUnwrap(SafetyStrings.contactLine(preference))
            XCTAssertEqual(description(), .text("Catatan buatan.\n\n\(line)"))
        }
        let saved = try await store.reportDraft()
        XCTAssertEqual(saved?.fields.first { $0.fieldName == .description }?.value, .text("Catatan buatan."))

        let full = String(repeating: "a", count: 5000)
        let fullDraft = ReportDraft(fields: [.init(fieldName: .description, value: .text(full), status: .editedByHer)])
        XCTAssertEqual(ReportFlow.withContactLine(fullDraft, preference: .noWhatsApp), fullDraft)
    }

    func testTrackerSampleNeverShowsOnTheRealTarget() {
        XCTAssertFalse(ReportTrackerSample.isAvailable(for: .real))
        XCTAssertTrue(ReportTrackerSample.isAvailable(for: .mock))
        XCTAssertTrue(SafetyStrings.trackerStages.indices.contains(ReportTrackerSample.currentStage))
    }

    func testFailedRefreshKeepsSavedEdits() async throws {
        let store = InMemoryEiraStore()
        let client = RecordingReportClient()
        let flow = ReportFlow(dependencies: .init(store: store, serverClient: client))
        _ = await flow.edit(.description, text: "Catatan buatan yang aku ubah.")
        let before = flow.draft
        await client.setFailure(true)
        await flow.refresh()
        XCTAssertEqual(flow.draft, before)
        XCTAssertNotNil(flow.errorMessage)
        let saved = try await store.reportDraft()
        XCTAssertEqual(saved, before)
    }
}
