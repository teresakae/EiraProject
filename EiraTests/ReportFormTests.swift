import XCTest
import SwiftUI
import WebKit
@testable import Eira

@MainActor
final class ReportFormTests: XCTestCase {
    private func window(for controller: UIViewController) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return window
    }

    private func waitForFill(_ loader: ReportFormLoader) async throws {
        let deadline = ContinuousClock.now + .seconds(15)
        while !loader.isFilled && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(50)) }
        XCTAssertTrue(loader.isFilled, "The bundled mock should load and fill all 17 controls.")
    }

    private func snapshot(_ view: UIView, name: String) {
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: true) }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func snapshot(_ webView: WKWebView, name: String) async throws {
        let image = try await webView.takeSnapshot(configuration: nil)
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testS1S3BundledMockFillsAllFieldsButOnlyReceivesOnItsOwnButton() async throws {
        let values: [ReportFieldName: ReportValue] = [
            .isVictim: .text("saya_sendiri"), .levelConcern: .text("khawatir"),
            .relationshipWithVictim: .text("Suami/Istri"), .incidentTime: .text("Malam"),
            .location: .text("Rumah Tangga"), .provinceCity: .text("Kota Bekasi, Jawa Barat"),
            .description: .text("Catatan buatan: \"aku mengubah isian ini\".\n</script><img src=x onerror='window.injected=true'>"),
            .victimFullName: .text("Nama Contoh"), .victimGender: .text("perempuan"), .victimAge: .integer(32),
            .victimDisabilities: .boolean(true),
            .victimDisabilitiesType: .text("Mengalami kesulitan mendengar, meskipun menggunakan alat bantu dengar"),
            .victimContactNumber: .text("080000000001"), .victimTrustedPerson: .text("080000000002"),
            .reporterFullName: .text("Nama Contoh Kedua"), .anonymous: .boolean(false), .contactNumber: .text("080000000003")]
        let draft = ReportDraft(fields: ReportFieldName.allCases.map {
            ReportDraftField(fieldName: $0, value: values[$0], status: .editedByHer)
        })
        var failures: [String] = []
        let loader = ReportFormLoader(draft: draft, target: .mock) { failures.append($0) }
        let webView = loader.makeWebView()
        let controller = UIViewController()
        controller.view = webView
        let window = try window(for: controller)
        defer { window.isHidden = true; webView.stopLoading() }
        XCTAssertFalse(webView.configuration.websiteDataStore.isPersistent)
        try await waitForFill(loader)
        XCTAssertTrue(failures.isEmpty)
        let controls = try await webView.evaluateJavaScript("Object.fromEntries(Array.from(document.querySelectorAll('[name]')).map(el => [el.name, el.value]))")
        let actual = try XCTUnwrap(controls as? [String: String])
        XCTAssertEqual(actual.count, 17)
        for name in ReportFieldName.allCases { XCTAssertEqual(actual[name.rawValue], ReportFields.text(values[name]), name.rawValue) }
        let before = try await webView.evaluateJavaScript("document.getElementById('received-values').textContent") as? String
        XCTAssertEqual(before, "")
        let injected = try await webView.evaluateJavaScript("Boolean(window.injected) || document.querySelector('img') !== null") as? Bool
        XCTAssertEqual(injected, false)
        try await snapshot(webView, name: "Mock form before her press")

        // Test-only simulation of her press on the local mock, never a real form.
        _ = try await webView.evaluateJavaScript("document.getElementById('send').click()")
        let receipt = try await webView.evaluateJavaScript("document.getElementById('received-values').textContent") as? String
        let data = try XCTUnwrap(receipt?.data(using: .utf8))
        let received = try JSONDecoder().decode([String: ReportValue].self, from: data)
        for name in ReportFieldName.allCases { XCTAssertEqual(received[name.rawValue], values[name], name.rawValue) }
        try await snapshot(webView, name: "Mock receipt after her press")

        // Both the CSP and native navigation policy protect the mock from outgoing loads.
        let networkBlocked = try await webView.callAsyncJavaScript(
            "try { await fetch('https://example.invalid/'); return false; } catch { return true; }", in: nil, contentWorld: .page) as? Bool
        XCTAssertEqual(networkBlocked, true)
        let originalURL = webView.url
        webView.load(URLRequest(url: try XCTUnwrap(URL(string: "https://example.invalid/"))))
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(webView.url, originalURL)
    }

    func testS2RealTargetFailsClosedWithoutLoadingAnyPage() async throws {
        let failed = expectation(description: "Real form is deferred")
        let loader = ReportFormLoader(draft: .init(), target: .real) { text in
            XCTAssertEqual(text, SafetyStrings.realDeferred)
            failed.fulfill()
        }
        let webView = loader.makeWebView()
        await fulfillment(of: [failed], timeout: 3)
        XCTAssertNil(webView.url)
        XCTAssertFalse(loader.isFilled)
        #if DEBUG
        XCTAssertEqual(ReportTarget.current, .mock)
        #endif
    }

    func testMockPreservesEmptyFieldsAndFalseValues() async throws {
        let draft = ReportDraft(fields: [ReportDraftField(fieldName: .anonymous, value: .boolean(false), status: .editedByHer)])
        let loader = ReportFormLoader(draft: draft, target: .mock) { XCTFail($0) }
        let webView = loader.makeWebView()
        let controller = UIViewController()
        controller.view = webView
        let window = try window(for: controller)
        defer { window.isHidden = true }
        try await waitForFill(loader)
        let emptyAge = try await webView.evaluateJavaScript("document.getElementById('korban_age').value") as? String
        let anonymous = try await webView.evaluateJavaScript("document.getElementById('anonymous').value") as? String
        XCTAssertEqual(emptyAge, "")
        XCTAssertEqual(anonymous, "false")
    }

    func testN1ReviewAndConfirmationRenderWithoutReportingNudges() async throws {
        let store = InMemoryEiraStore()
        try await store.saveEntry(Entry(text: CannedServerClient.sampleEntryText))
        let dependencies = AppDependencies(store: store)
        let flow = ReportFlow(dependencies: dependencies)
        await flow.refresh()
        let review = UIHostingController(rootView: NavigationStack { ReportScreen(dependencies: dependencies) })
        let window = try window(for: review)
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(500))
        snapshot(review.view, name: "Report review with source and states")
        await flow.prepareConfirmation()
        let confirmation = UIHostingController(rootView: NavigationStack {
            ReportConfirmationScreen(flow: flow)
        })
        window.rootViewController = confirmation
        try await Task.sleep(for: .milliseconds(500))
        snapshot(confirmation.view, name: "Draft confirmation before form")
        XCTAssertEqual(flow.stage, .confirmation)
        let copy = [SafetyStrings.shared, SafetyStrings.recipient, SafetyStrings.sheSends,
            SafetyStrings.unknowns, SafetyStrings.risks, SafetyStrings.anonymity, SafetyStrings.privacy].joined(separator: " ")
        for banned in ["sebaiknya melapor", "lapor sekarang", "harus melapor", "Eira membuatmu aman", "lawyer-checked"] {
            XCTAssertFalse(copy.contains(banned))
        }
    }

    func testV1AskChatShowsReplyAndCaveat() async throws {
        let store = InMemoryEiraStore()
        try await store.saveEntry(Entry(text: CannedServerClient.sampleEntryText))
        let flow = AskFlow(dependencies: .init(store: store, serverClient: RecordingReportClient(faq: [7])))
        _ = await flow.send("Apa pilihanku?")
        let controller = UIHostingController(rootView: NavigationStack { AskScreen(flow: flow) })
        let window = try window(for: controller)
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(500))
        snapshot(controller.view, name: "Ask reply with lawyer caveat")
        XCTAssertTrue(AskFlow.needsLawyerCaveat(try XCTUnwrap(flow.turns.last?.response)))
        let entry = try XCTUnwrap(flow.turns.first?.entry)
        await flow.setUses(.init(personalTimeline: true, legalGuidance: false, report: false), for: entry.id)
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(flow.turns.count, 1)
        XCTAssertNil(flow.turns.first?.response)
        snapshot(controller.view, name: "Ask question with restricted uses")
    }

    func testSourceAndManualEditAtLargeTextSize() async throws {
        let entry = Entry(text: CannedServerClient.sampleEntryText)
        let field = QuoteCheck.validated(ReportDraftField(fieldName: .description, value: .text(entry.text), quote: entry.text), against: [entry])
        let controller = UIHostingController(rootView: ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ReportFieldSummary(field: field)
                Divider()
                ReportFieldSummary(field: .init(fieldName: .provinceCity, value: .text("Kota Bekasi, Jawa Barat"), status: .editedByHer))
            }.padding()
        }.dynamicTypeSize(.accessibility3))
        let window = try window(for: controller)
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(500))
        snapshot(controller.view, name: "Sources and manual edits at large text size")
    }
}
