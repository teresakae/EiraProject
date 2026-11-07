import XCTest
import SwiftUI
@testable import Eira

@MainActor
final class DiaryDesignTests: XCTestCase {
    func testFontsLoadAndRenderDiary() async throws {
        XCTAssertNotNil(UIFont(name: "EiraFraunces-Regular", size: 16))
        XCTAssertNotNil(UIFont(name: "EiraFraunces-Bold", size: 24))
        XCTAssertNotNil(UIFont(name: "PlusJakartaSans-Regular", size: 14))
        let dependencies = AppDependencies()
        let screen = NavigationStack {
            WriteScreen(flow: WriteFlow(dependencies: dependencies), voice: VoiceFlow(client: dependencies.serverClient))
        }
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
        let attachment = XCTAttachment(image: image)
        attachment.name = "Diary entry"
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }
}
