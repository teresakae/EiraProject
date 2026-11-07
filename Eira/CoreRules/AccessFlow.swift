import Foundation
import Observation

@MainActor @Observable
final class AccessFlow {
    enum Gate { case pin, migration }
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
        if title == "Eira" {
            guard !isInactive, !Task.isCancelled else { return }
            guard workspace == nil else { return }
            gate = .pin
            errorMessage = nil
        } else if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try store.saveCoverTask(CoverTask(title: title))
        }
    }

    func submitPIN(_ pin: String) -> Bool {
        guard gate == .pin, !isInactive else { return false }
        guard pin == "1111" else {
            errorMessage = "Incorrect PIN. Try again."
            return false
        }
        do {
            try store.open()
            workspace = PrivateWorkspace(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
            gate = nil
            errorMessage = nil
            return true
        } catch StoreError.migrationRequired {
            gate = .migration
            errorMessage = nil
            return true
        } catch {
            errorMessage = "The notes could not be opened. Try again."
            return false
        }
    }

    func open(passphrase: String) async -> Bool {
        guard gate == .migration, !isInactive else { return false }
        let token = UUID()
        attempt = token
        errorMessage = nil
        do {
            try await store.migrate(passphrase: passphrase)
            guard token == attempt, !Task.isCancelled else { store.lock(); return false }
            workspace = PrivateWorkspace(dependencies: .init(store: PrivateSessionStore(store), serverClient: client))
            self.gate = nil
            return true
        } catch {
            if token == attempt {
                errorMessage = "Could not open your entries. Check your passphrase and try again. Existing entries have not changed."
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
            gate = nil
            errorMessage = "The change could not be completed. Try again."
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
