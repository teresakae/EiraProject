import XCTest
import SwiftUI
@testable import Eira

@MainActor
final class CoverDesignTests: XCTestCase {
    func testLegacyTaskAndNotesRoundTripWithoutOpeningPrivateStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = EncryptedEiraStore(directory: directory)
        let original = CoverTask(title: "Daftar belanja", isCompleted: true)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        object.removeValue(forKey: "body")
        object.removeValue(forKey: "is_pinned")
        object.removeValue(forKey: "checklist")
        let legacy = try JSONDecoder().decode(CoverTask.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(legacy.title, original.title)
        XCTAssertTrue(legacy.isCompleted)
        XCTAssertNil(legacy.checklist)
        try store.saveCoverTask(legacy)
        var note = CoverTask(title: "Ide menu mingguan")
        note.body = "Senin: tumis sayur."
        note.isPinned = true
        note.checklist = [CoverChecklistItem(text: "Beli sayur", isCompleted: true)]
        try store.saveCoverTask(note)
        let reopened = EncryptedEiraStore(directory: directory)
        XCTAssertEqual(try reopened.coverTasks(), [legacy, note])
        XCTAssertFalse(reopened.isUnlocked)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("records.sealed").path))
        try reopened.deleteCoverTask(id: note.id)
        XCTAssertEqual(try reopened.coverTasks(), [legacy])
    }

    func testNotesAndPINRender() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = EncryptedEiraStore(directory: directory)
        var pinned = CoverTask(title: "Rencana akhir pekan")
        pinned.body = "Cuci baju · Bersihkan kamar · Belanja sayur"
        pinned.isPinned = true
        try store.saveCoverTask(pinned)
        var shopping = CoverTask(title: "Daftar belanja")
        shopping.body = "Jangan lupa bawa tas belanja sendiri.\n\nCek stok di dapur sebelum berangkat."
        shopping.checklist = [CoverChecklistItem(text: "Telur dan susu", isCompleted: true), CoverChecklistItem(text: "Tomat dan sayuran", isCompleted: true), CoverChecklistItem(text: "Sabun cuci"), CoverChecklistItem(text: "Minyak goreng"), CoverChecklistItem(text: "Kopi")]
        try store.saveCoverTask(shopping)
        try store.saveCoverTask(CoverTask(title: "Ide menu mingguan"))
        try store.saveCoverTask(CoverTask(title: "Jadwal keluarga"))
        try await snapshot(CoverScreen(access: AccessFlow(store: store)), name: "notes-home")
        try await snapshot(CoverNoteEditor(note: shopping) { _ in }, name: "note-editor")
        try await snapshot(CoverPINScreen(onCancel: {}, onSubmit: { _ in }), name: "note-pin")
    }

    private func snapshot(_ screen: some View, name: String) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let host = UIHostingController(rootView: screen)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(300))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/eira-\(name).png"))
        window.isHidden = true
    }
}
