import Foundation
import Observation

@MainActor @Observable
final class AccessFlow {
    enum Gate { case setup, unlock }
    let store: EncryptedEiraStore
    private let client: any ServerClient
    private var attempt = UUID()
    private(set) var workspace: PrivateWorkspace?
    private(set) var isInactive = false
    var gate: Gate?
    var errorMessage: String?

    init(store: EncryptedEiraStore = EncryptedEiraStore(), client: any ServerClient = CannedServerClient()) {
        self.store = store
        self.client = client
    }

    // Called with the unmodified title; case and whitespace are significant.
    func addTask(_ title: String) async throws {
        if title == "eira" {
            gate = store.needsSetup ? .setup : .unlock
        } else if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try store.saveCoverTask(CoverTask(title: title))
        }
    }

    func open(passphrase: String) async -> Bool {
        guard let gate else { return false }
        let token = UUID()
        attempt = token
        errorMessage = nil
        do {
            if gate == .setup { try await store.setup(passphrase: passphrase) }
            else { try await store.unlock(passphrase: passphrase) }
            guard token == attempt, !Task.isCancelled else { store.lock(); return false }
            workspace = PrivateWorkspace(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
            self.gate = nil
            return true
        } catch {
            if token == attempt {
                errorMessage = "Belum bisa dibuka. Periksa frasa sandimu dan coba lagi. Catatan yang ada tidak diubah."
            }
            return false
        }
    }

    func cancelAccess() {
        attempt = UUID()
        gate = nil
        errorMessage = nil
        store.lock()
    }

    func setInactive(_ inactive: Bool) { isInactive = inactive }

    func lock() {
        workspace?.stop()
        workspace = nil
        cancelAccess()
    }

    func deleteEverything() async {
        do { try store.deleteSecretData(); lock() }
        catch {
            workspace?.stop()
            workspace = nil
            gate = .unlock
            errorMessage = "Data belum terhapus. Buka kembali dan coba hapus lagi."
        }
    }
}

@MainActor
final class PrivateWorkspace: Identifiable {
    let id = UUID()
    let dependencies: AppDependencies
    let write: WriteFlow
    let voice: VoiceFlow

    init(dependencies: AppDependencies) {
        let scoped = AppDependencies(store: dependencies.store, serverClient: dependencies.serverClient,
            lifetime: SessionLifetime())
        self.dependencies = scoped
        write = WriteFlow(dependencies: scoped)
        voice = VoiceFlow(client: scoped.serverClient)
    }

    func stop() {
        dependencies.lifetime?.lock()
        dependencies.serverClient.cancelPendingRequests()
        write.stop()
        voice.cancel()
    }
}
