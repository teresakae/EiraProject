import XCTest
@testable import Eira

private final class ServerContractStub: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() { }
    override func startLoading() {
        do {
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer invented-test-token")
            let data: Data
            let status: Int
            switch request.url?.path {
            case "/api/extract":
                data = try JSONEncoder().encode(ExtractResponse(events: [], coverTask: "Rapikan meja", reply: "Contoh."))
                status = 200
            case "/api/ask":
                data = try JSONEncoder().encode(AskResponse(answer: "Contoh.", faqAnswersUsed: [], articlesNamed: [], notSure: true))
                status = 200
            case "/api/draft":
                data = try JSONEncoder().encode(DraftResponse(fields: [:]))
                status = 200
            case "/api/transcribe":
                XCTAssertTrue(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
                data = Data(#"{"text":"Teks contoh buatan."}"#.utf8)
                status = 200
            default:
                data = Data(#"{"error":{"code":"unauthorized","message":"Contoh"}}"#.utf8)
                status = 401
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                headerFields: ["Content-Type": "application/json", "Cache-Control": "no-store"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
}

@MainActor
final class HTTPServerClientTests: XCTestCase {
    func testAllFourEndpointContractsAndAuthentication() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ServerContractStub.self]
        let client = HTTPServerClient(baseURL: URL(string: "https://example.invalid"), token: "invented-test-token",
            session: URLSession(configuration: configuration))
        let extracted = try await client.extract(.init(text: "Catatan buatan."))
        XCTAssertEqual(extracted.coverTask, "Rapikan meja")
        let asked = try await client.ask(.init(question: "Contoh?", conversation: [], entries: [], events: []))
        XCTAssertTrue(asked.notSure)
        let draft = try await client.draft(.init(entries: []))
        XCTAssertEqual(draft.fields.count, 17)
        let text = try await client.transcribe(.init(audio: Data([1, 2]), filename: "invented.m4a", contentType: "audio/mp4"))
        XCTAssertEqual(text, "Teks contoh buatan.")
    }

    func testMissingTokenAndNonLoopbackHTTPFailClosed() async throws {
        for client in [
            HTTPServerClient(baseURL: URL(string: "https://example.invalid"), token: ""),
            HTTPServerClient(baseURL: URL(string: "http://example.invalid"), token: "invented-test-token")
        ] {
            do { _ = try await client.extract(.init(text: "Contoh buatan.")); XCTFail("Invalid configuration accepted") }
            catch is ServerClientError { }
        }
    }

    func testLocalServerM1ThroughWriteAndAllEndpoints() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["EIRA_LIVE_TESTS"] == "1", "Local server checks are opt-in and use API credits.")
        let client = HTTPServerClient.configured()
        let m1 = "Semalam sekitar jam 11 suamiku pulang mabuk, marah gara-gara nasi belum matang. Dia nampar pipi kiriku dua kali terus ndorong aku sampe kepala kebentur lemari. Pipiku masih bengkak. Anak-anak di kamar, yang gede (Dimas, 9 th) lihat dari pintu. Minggu lalu dia juga bilang aku \"gak berguna, mending mati aja\". Bulan ini dia belum kasih uang belanja sama sekali."
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = EncryptedEiraStore(directory: directory)
        defer { try? store.deleteSecretData(); try? FileManager.default.removeItem(at: directory) }
        try store.open()
        let dependencies = AppDependencies(store: PrivateSessionStore(store), serverClient: client)
        let flow = WriteFlow(dependencies: dependencies)
        let sent = await flow.send(m1)
        XCTAssertTrue(sent)
        XCTAssertNil(flow.errorMessage)
        XCTAssertEqual(flow.events.count, 3)
        XCTAssertEqual(Set(flow.events.map(\.violenceType)), [.physical, .psychological, .neglect])
        XCTAssertTrue(flow.events.allSatisfy { QuoteCheck.contains($0.quote, in: m1) })
        let entry = try XCTUnwrap(flow.entries.first)
        XCTAssertEqual(entry.text, m1)
        XCTAssertFalse(try XCTUnwrap(entry.writeReply).isEmpty)
        let coverTask = try XCTUnwrap(store.coverTasks().first)
        XCTAssertNotEqual(coverTask.title, "Eira")
        XCTAssertFalse(coverTask.title.isEmpty)
        let ask = AskFlow(dependencies: dependencies)
        let question = "Kalau aku lapor, apa suamiku langsung ditangkap?"
        let asked = await ask.send(question)
        XCTAssertTrue(asked)
        XCTAssertNil(ask.errorMessage)
        let answer = try XCTUnwrap(ask.turns.last?.response)
        XCTAssertTrue(answer.notSure)
        XCTAssertTrue(answer.faqAnswersUsed.isEmpty)
        XCTAssertTrue(answer.articlesNamed.isEmpty)
        let report = ReportFlow(dependencies: dependencies)
        await report.refresh()
        XCTAssertNil(report.errorMessage)
        XCTAssertEqual(report.draft.fields.count, 17)
        let description = try XCTUnwrap(report.draft.fields.first { $0.fieldName == .description })
        XCTAssertNotNil(description.value)
        XCTAssertEqual(description.sourceEntryID, entry.id)
        XCTAssertTrue(QuoteCheck.contains(description.quote, in: m1))
        XCTAssertTrue(try store.entries().contains { $0.kind == .question && $0.text == question })
        let edited = await report.edit(.provinceCity, text: "Kota Bekasi, Jawa Barat")
        XCTAssertTrue(edited)
        store.lock()
        try store.open()
        let reopened = ReportFlow(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
        await reopened.load()
        XCTAssertEqual(reopened.draft.fields.first { $0.fieldName == .provinceCity }?.value,
                       .text("Kota Bekasi, Jawa Barat"))
        XCTAssertEqual(reopened.draft.fields.first { $0.fieldName == .provinceCity }?.status, .editedByHer)
        if let path = ProcessInfo.processInfo.environment["EIRA_LIVE_AUDIO"] {
            let audioURL = directory.appendingPathComponent("audio.m4a")
            try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: audioURL)
            let voice = VoiceFlow(client: client)
            let text = try await voice.transcribeFile(audioURL)
            XCTAssertFalse(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
            print("Local transcription returned editable text (invented synthetic audio).")
        }
        print("M1: \(flow.events.count) validated events; reply: \(entry.writeReply ?? ""); cover task: \(coverTask.title); Ask: \(answer.answer)")
    }
}
