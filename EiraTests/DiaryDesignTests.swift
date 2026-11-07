import XCTest
import SwiftUI
@testable import Eira

@MainActor
final class DiaryDesignTests: XCTestCase {
    func testEnglishHomeAndNavigationPreserveOriginalEntries() async throws {
        let store = InMemoryEiraStore()
        let original = CannedServerClient.sampleEntryText
        try await store.saveEntry(Entry(text: original))
        let dependencies = AppDependencies(store: store)
        let workspace = PrivateWorkspace(dependencies: dependencies)
        await workspace.write.load()
        XCTAssertEqual(workspace.write.entries.first?.text, original)
        XCTAssertEqual(SafetyStrings.display(.text("Pagi"), for: .description), "Pagi")
        XCTAssertEqual(SafetyStrings.display(.text("Pagi"), for: .incidentTime), "Morning")
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let host = UIHostingController(rootView: PrivateArea(workspace: workspace, access: AccessFlow())
            .environment(\.locale, Locale(identifier: "en")))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 440, height: 956)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(400))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/eira-english-home.png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = "English private home"
        attachment.lifetime = .keepAlways
        add(attachment)
        for field in ReportFieldName.allCases {
            for option in ReportFields.options(for: field) ?? [] {
                XCTAssertNotEqual(SafetyStrings.choice(option), option)
                XCTAssertTrue(ReportFields.valid(.text(option), for: field))
            }
        }
    }

    func testFontsLoadAndRenderDiary() async throws {
        XCTAssertNotNil(UIFont(name: "EiraFraunces-Regular", size: 16))
        XCTAssertNotNil(UIFont(name: "EiraFraunces-Bold", size: 24))
        XCTAssertNotNil(UIFont(name: "PlusJakartaSans-Regular", size: 14))
        let dependencies = AppDependencies()
        let screen = NavigationStack {
            WriteScreen(flow: WriteFlow(dependencies: dependencies), voice: VoiceFlow(client: dependencies.serverClient), onDone: {}, onTalk: {})
        }.environment(\.locale, Locale(identifier: "en"))
        let host = UIHostingController(rootView: screen)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 440, height: 956)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(300))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/eira-english-diary.png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = "Diary entry"
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }
}
