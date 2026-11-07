import XCTest
import CryptoKit
import Security
@testable import Eira

private actor CoverTestClient: ServerClient {
    var held = false
    var failing = false
    var continuation: CheckedContinuation<Void, Never>?
    var started: CheckedContinuation<Void, Never>?
    var extracting = false
    var extraction: ExtractResponse?

    func pause() { held = true }
    func fail() { failing = true }
    func respond(_ response: ExtractResponse) { extraction = response }
    func waitForExtract() async {
        if !extracting { await withCheckedContinuation { started = $0 } }
    }
    func resume() { held = false; continuation?.resume(); continuation = nil }

    func extract(_ request: ExtractRequest) async throws -> ExtractResponse {
        extracting = true
        started?.resume(); started = nil
        if held { await withCheckedContinuation { continuation = $0 } }
        if failing { throw URLError(.notConnectedToInternet) }
        if let extraction { return extraction }
        return try await CannedServerClient().extract(request)
    }
    func transcribe(_ request: TranscribeRequest) async throws -> String {
        if failing { throw URLError(.notConnectedToInternet) }
        return try await CannedServerClient().transcribe(request)
    }
    func ask(_ request: AskRequest) async throws -> AskResponse { try await CannedServerClient().ask(request) }
    func draft(_ request: DraftRequest) async throws -> DraftResponse { try await CannedServerClient().draft(request) }
}

@MainActor
final class CoverWriteTests: XCTestCase {
    private let phrase = "Sapu biru menunggu pagi 726"

    func testPasswordDerivationMatchesIndependentSHA256Vector() throws {
        let key = try PrivateEncryption.passwordKey("example phrase", salt: Data(0..<32))
        let hex = key.withUnsafeBytes { bytes in bytes.map { String(format: "%02x", $0) }.joined() }
        XCTAssertEqual(hex, "5bb00c616fb728ee1abc1560144dfb6f7d140a5e8a530d7aebfa330d00601ed2")
    }

    func testLockClearsAskAndReportCachesAndPreventsReuse() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        try store.open()
        let workspace = PrivateWorkspace(dependencies: .init(store: PrivateSessionStore(store)))
        let ask = AskFlow(dependencies: workspace.dependencies)
        let report = ReportFlow(dependencies: workspace.dependencies)
        _ = await ask.send("Pertanyaan buatan.")
        _ = await report.edit(.description, text: "Cerita contoh buatan")
        XCTAssertFalse(ask.turns.isEmpty)
        XCTAssertNotNil(report.draft.fields.first(where: { $0.fieldName == .description })?.value)
        workspace.stop()
        store.lock()
        XCTAssertTrue(ask.turns.isEmpty)
        XCTAssertTrue(report.draft.fields.allSatisfy { $0.value == nil })
        XCTAssertNil(report.deliveryDraft)
        try store.open()
        await ask.load()
        await report.load()
        XCTAssertTrue(ask.turns.isEmpty)
        XCTAssertTrue(report.draft.fields.allSatisfy { $0.value == nil })
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            await MainActor.run { try? EncryptedEiraStore(directory: url).deleteSecretData() }
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    func testDS1ExactTriggerAndCoverCRUDWithoutUnlock() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        let access = AccessFlow(store: store)
        for title in ["Eira", " eira", "eira ", "Beli sabun"] { try await access.addTask(title) }
        XCTAssertNil(access.gate)
        XCTAssertEqual(try store.coverTasks().map(\.title), ["Eira", " eira", "eira ", "Beli sabun"])
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNil(access.gate)
        XCTAssertNotNil(access.workspace)
        access.lock()
        XCTAssertEqual(try store.coverTasks().count, 4)
        var task = try XCTUnwrap(store.coverTasks().last)
        task.isCompleted = true
        try store.saveCoverTask(task)
        XCTAssertTrue(try XCTUnwrap(store.coverTasks().last).isCompleted)
        try store.deleteCoverTask(id: task.id)
        XCTAssertEqual(try store.coverTasks().count, 3)
        XCTAssertThrowsError(try store.entries())
    }

    func testPINGateRejectsBypassWrongPINAndCancelledOrBackgroundAccess() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        let access = AccessFlow(store: store)
        XCTAssertFalse(access.submitPIN("1111"))
        try await access.addTask("eira")
        for pin in ["", "111", "11111", "0000", " 1111"] {
            XCTAssertFalse(access.submitPIN(pin))
            XCTAssertEqual(access.gate, .pin)
            XCTAssertNil(access.workspace)
            XCTAssertFalse(store.isUnlocked)
            XCTAssertThrowsError(try store.entries())
        }
        XCTAssertEqual(access.errorMessage, "PIN salah. Coba lagi.")
        access.cancelAccess()
        XCTAssertNil(access.gate)
        XCTAssertNil(access.errorMessage)
        XCTAssertFalse(access.submitPIN("1111"))
        try await access.addTask("eira")
        access.setInactive(true)
        XCTAssertFalse(access.submitPIN("1111"))
        access.lock()
        access.setInactive(false)
        XCTAssertFalse(access.submitPIN("1111"))
        try await access.addTask("eira")
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNotNil(access.workspace)
        XCTAssertNil(access.errorMessage)
        XCTAssertTrue(store.isUnlocked)
        XCTAssertTrue(try store.coverTasks().isEmpty)
    }

    func testLegacyEncryptedRoundTripWrongPassphraseAndNoAutomaticUnlock() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        try await store.setup(passphrase: phrase)
        let entry = Entry(text: CannedServerClient.sampleEntryText)
        try store.saveEntry(entry)
        let bytes = try Data(contentsOf: directory.appendingPathComponent("records.sealed"))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains(entry.text))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains(phrase))
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        let restarted = EncryptedEiraStore(directory: directory)
        XCTAssertFalse(restarted.isUnlocked)
        XCTAssertThrowsError(try restarted.entries())
        do { try await restarted.unlock(passphrase: "wrong invented phrase"); XCTFail("Wrong phrase accepted") }
        catch { XCTAssertFalse(restarted.isUnlocked) }
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("records.sealed")), bytes)
        try await restarted.unlock(passphrase: phrase)
        XCTAssertEqual(try restarted.entries(), [entry])
        restarted.lock()
        XCTAssertFalse(restarted.isUnlocked)
        XCTAssertThrowsError(try restarted.entries())
    }

    func testB1HidesInactiveAndLocksBackgroundState() async throws {
        let access = AccessFlow(store: EncryptedEiraStore(directory: try directory()))
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNotNil(access.workspace)
        XCTAssertNil(access.gate)
        let workspace = try XCTUnwrap(access.workspace)
        workspace.write.text = "Contoh pribadi buatan."
        access.setInactive(true)
        XCTAssertTrue(access.isInactive)
        access.lock()
        XCTAssertNil(access.workspace)
        XCTAssertNil(access.gate)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(workspace.write.text.isEmpty)
        XCTAssertTrue(workspace.write.entries.isEmpty)
        try await access.addTask("eira")
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        access.setInactive(false)
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNil(access.gate)
        XCTAssertNotNil(access.workspace)
        XCTAssertTrue(access.store.isUnlocked)
    }

    func testDeviceKeyRoundTripAndMissingKeyNeverReplacesRecords() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        try store.open()
        let entry = Entry(text: "Catatan pengujian buatan untuk penyimpanan ponsel.")
        try store.saveEntry(entry)
        store.lock()
        let restarted = EncryptedEiraStore(directory: directory)
        XCTAssertFalse(restarted.isUnlocked)
        try restarted.open()
        XCTAssertEqual(try restarted.entries(), [entry])
        let file = directory.appendingPathComponent("records.sealed")
        let bytes = try Data(contentsOf: file)
        let envelope = try JSONDecoder().decode(PrivateEncryption.Envelope.self, from: bytes)
        XCTAssertEqual(envelope.version, 2)
        XCTAssertTrue(envelope.wrappedKey.isEmpty)
        XCTAssertTrue(envelope.salt.isEmpty)
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains(entry.text))
        var attributes: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "org.eira.app.private-records",
            kSecAttrAccount as String: directory.lastPathComponent,
            kSecReturnAttributes as String: true]
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &attributes), errSecSuccess)
        let stored = try XCTUnwrap(attributes as? [String: Any])
        XCTAssertEqual(stored[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        XCTAssertEqual(stored[kSecAttrSynchronizable as String] as? Bool, false)
        restarted.lock()
        try DeviceKeyStore.delete(account: directory.lastPathComponent)
        XCTAssertThrowsError(try restarted.open())
        XCTAssertFalse(restarted.isUnlocked)
        XCTAssertFalse(restarted.needsSetup)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testOneTimeMigrationPreservesRecordsAndRejectsWrongPassphrase() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        try await store.setup(passphrase: phrase)
        let entry = Entry(text: CannedServerClient.sampleEntryText)
        try store.saveEntry(entry)
        try store.saveCoverTask(CoverTask(title: "Beli sabun"))
        let draft = ReportDraft(fields: [.init(fieldName: .provinceCity,
            value: .text("Kota Bekasi, Jawa Barat"), status: .editedByHer)])
        try store.saveReportDraft(draft)
        store.lock()
        let file = directory.appendingPathComponent("records.sealed")
        let bytes = try Data(contentsOf: file)
        let access = AccessFlow(store: store)
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertEqual(access.gate, .migration)
        XCTAssertNil(access.workspace)
        let wrong = await access.open(passphrase: "wrong invented phrase")
        XCTAssertFalse(wrong)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let opened = await access.open(passphrase: phrase)
        XCTAssertTrue(opened)
        XCTAssertNil(access.gate)
        XCTAssertEqual(try store.entries(), [entry])
        XCTAssertEqual(try store.reportDraft(), draft)
        XCTAssertEqual(try store.coverTasks().map(\.title), ["Beli sabun"])
        let envelope = try JSONDecoder().decode(PrivateEncryption.Envelope.self, from: Data(contentsOf: file))
        XCTAssertEqual(envelope.version, 2)
        XCTAssertTrue(envelope.wrappedKey.isEmpty)
        access.lock()
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNil(access.gate)
        XCTAssertNotNil(access.workspace)
        XCTAssertEqual(try store.entries(), [entry])
    }

    func testDL1DeletionPreservesCoverAndRequiresFreshSetup() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        let access = AccessFlow(store: store)
        try await access.addTask("Beli sabun")
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNotNil(access.workspace)
        XCTAssertNil(access.gate)
        let oldSession = PrivateSessionStore(store)
        try store.saveEntry(Entry(text: "Catatan buatan untuk dihapus."))
        try store.saveReportDraft(ReportDraft())
        let tasks = try store.coverTasks()
        await access.deleteEverything()
        XCTAssertThrowsError(try DeviceKeyStore.load(account: directory.lastPathComponent))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("records.sealed").path))
        XCTAssertEqual(try store.coverTasks(), tasks)
        XCTAssertNil(access.workspace)
        try await access.addTask("eira")
        XCTAssertEqual(access.gate, .pin)
        XCTAssertNil(access.workspace)
        XCTAssertFalse(access.store.isUnlocked)
        XCTAssertTrue(access.submitPIN("1111"))
        XCTAssertNil(access.gate)
        XCTAssertNotNil(access.workspace)
        XCTAssertTrue(try store.entries().isEmpty)
        XCTAssertTrue(try store.events().isEmpty)
        XCTAssertNil(try store.reportDraft())
        do { try await oldSession.saveEntry(Entry(text: "Late invented response")); XCTFail("Old session accepted") }
        catch { }
        XCTAssertTrue(try store.entries().isEmpty)
    }

    func testCV1WritePersistsExactTextQuoteReplyAndSeparateCoverTask() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        try store.open()
        let flow = WriteFlow(dependencies: .init(store: PrivateSessionStore(store)))
        let before = Date()
        let saved = await flow.send(CannedServerClient.sampleEntryText, source: .voice)
        XCTAssertTrue(saved)
        let entry = try XCTUnwrap(flow.entries.first)
        XCTAssertEqual(entry.text, CannedServerClient.sampleEntryText)
        XCTAssertEqual(entry.source, .voice)
        XCTAssertGreaterThanOrEqual(entry.createdAt, before)
        XCTAssertLessThanOrEqual(entry.createdAt, Date())
        XCTAssertEqual(flow.timeline.count, 1)
        XCTAssertTrue(QuoteCheck.contains(flow.timeline.first?.quote, in: entry.text))
        XCTAssertNotNil(entry.writeReply)
        let tasks = try store.coverTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Rapikan meja")
        let coverJSON = try Data(contentsOf: directory.appendingPathComponent("tasks.json"))
        XCTAssertFalse(String(decoding: coverJSON, as: UTF8.self).contains(entry.id.uuidString))
        XCTAssertFalse(String(decoding: coverJSON, as: UTF8.self).contains(entry.text))
        flow.stop(); store.lock()
        XCTAssertEqual(try store.coverTasks(), tasks)
        try store.open()
        XCTAssertEqual(try store.entries().first?.writeReply, entry.writeReply)
    }

    func testAllowedUsesHideTimelineAndFilterLaterRequestsAndEditsSurviveReopen() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        try store.open()
        let flow = WriteFlow(dependencies: .init(store: PrivateSessionStore(store)))
        await flow.send(CannedServerClient.sampleEntryText)
        let event = try XCTUnwrap(flow.events.first)
        await flow.setType(.unsure, for: event.id)
        XCTAssertEqual(flow.events.first?.violenceType, .unsure)
        XCTAssertEqual(flow.events.first?.userEdited, true)
        let id = try XCTUnwrap(flow.entries.first?.id)
        await flow.setUses(.init(personalTimeline: false, legalGuidance: false, report: false), for: id)
        XCTAssertTrue(flow.timeline.isEmpty)
        XCTAssertEqual(flow.entries.count, 1)
        XCTAssertTrue(AskRequest(question: "Contoh?", conversation: [], entries: flow.entries, events: flow.events).entries.isEmpty)
        XCTAssertTrue(DraftRequest(entries: flow.entries).entries.isEmpty)
        store.lock()
        try store.open()
        XCTAssertFalse(try XCTUnwrap(store.entries().first).allowedUses.report)
        XCTAssertEqual(try store.events().first?.userEdited, true)
    }

    func testQ1InvalidQuotesDroppedIncludingReplyAsSource() async throws {
        let client = CoverTestClient()
        let text = "Contoh buatan tanpa nama."
        let reply = "Balasan buatan saja."
        let invalid = ExtractedEvent(whenText: nil, whatHappened: "Ditolak", injuries: nil,
            witnesses: [], quote: reply, violenceType: .unsure)
        await client.respond(.init(events: [invalid], coverTask: "Rapikan meja", reply: reply))
        let store = EncryptedEiraStore(directory: try directory())
        try store.open()
        let flow = WriteFlow(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
        for _ in 0..<5 {
            await flow.send(text)
            XCTAssertTrue(flow.events.isEmpty)
        }
        XCTAssertEqual(flow.entries.last?.writeReply, reply)
        XCTAssertFalse(DraftRequest(entries: flow.entries).entries.contains(reply))
        XCTAssertTrue(flow.entries.allSatisfy { $0.text == text })
    }

    func testQ5R1CannedM1AndX1NeverInventNamesAndRepliesStaySeparate() async throws {
        let samples = [
            "Semalam sekitar jam 11 suamiku pulang mabuk, marah gara-gara nasi belum matang. Dia nampar pipi kiriku dua kali terus ndorong aku sampe kepala kebentur lemari. Pipiku masih bengkak. Anak-anak di kamar, yang gede (Dimas, 9 th) lihat dari pintu. Minggu lalu dia juga bilang aku \"gak berguna, mending mati aja\". Bulan ini dia belum kasih uang belanja sama sekali.",
            "Dulu aku kerja, tapi dia suruh aku berhenti. Sekarang kalau mau beli apa-apa aku harus minta dulu."
        ]
        for sample in samples {
            let response = try await CannedServerClient().extract(.init(text: sample))
            XCTAssertTrue(response.events.isEmpty)
            XCTAssertEqual(response.reply, "Aku belum bisa mengurai catatan ini.")
        }
        // This proves the canned contract only, not extraction or language quality of a live model.
    }

    func testLateResponseAfterLockAndFreshUnlockCannotRestorePrivateState() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        try store.open()
        let client = CoverTestClient()
        await client.pause()
        let flow = WriteFlow(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
        let pending = Task { await flow.send(CannedServerClient.sampleEntryText) }
        await client.waitForExtract()
        flow.stop(); store.lock()
        try store.open()
        await client.resume()
        _ = await pending.value
        XCTAssertTrue(flow.entries.isEmpty)
        XCTAssertTrue(flow.events.isEmpty)
        XCTAssertTrue(try store.events().isEmpty)
        XCTAssertNil(try store.entries().first?.writeReply)
        XCTAssertTrue(try store.coverTasks().isEmpty)
    }

    func testChangingAllowedUsesWhileExtractingSurvivesReply() async throws {
        let store = EncryptedEiraStore(directory: try directory())
        try store.open()
        let client = CoverTestClient()
        await client.pause()
        let flow = WriteFlow(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
        let pending = Task { await flow.send(CannedServerClient.sampleEntryText) }
        await client.waitForExtract()
        let id = try XCTUnwrap(flow.entries.first?.id)
        let uses = AllowedUses(personalTimeline: false, legalGuidance: false, report: false)
        await flow.setUses(uses, for: id)
        await client.resume()
        _ = await pending.value
        XCTAssertEqual(flow.entries.first?.allowedUses, uses)
        XCTAssertEqual(try store.entries().first?.allowedUses, uses)
        XCTAssertTrue(flow.timeline.isEmpty)
        XCTAssertNotNil(flow.entries.first?.writeReply)
    }

    func testA1AudioDeletedOnSuccessAndFailure() async throws {
        let directory = try directory()
        for fails in [false, true] {
            let client = CoverTestClient()
            if fails { await client.fail() }
            let voice = VoiceFlow(client: client)
            let file = directory.appendingPathComponent("invented.m4a")
            try Data([1, 2, 3]).write(to: file)
            do {
                let text = try await voice.transcribeFile(file)
                XCTAssertFalse(fails)
                XCTAssertEqual(text, CannedServerClient.sampleEntryText)
            } catch { XCTAssertTrue(fails) }
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        }
    }

    func testCorruptedCiphertextDoesNotOpenOrResetSetup() async throws {
        let directory = try directory()
        let store = EncryptedEiraStore(directory: directory)
        try store.open()
        store.lock()
        let file = directory.appendingPathComponent("records.sealed")
        try Data("broken invented envelope".utf8).write(to: file)
        do { try store.open(); XCTFail("Corrupt store opened") } catch { }
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.needsSetup)
        do { try store.open(); XCTFail("Corrupt store overwritten") } catch { }
        XCTAssertEqual(try Data(contentsOf: file), Data("broken invented envelope".utf8))
    }
}
