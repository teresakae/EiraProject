import Foundation
import CryptoKit

enum StoreError: Error { case locked, alreadyCreated, missing, invalidPassphrase, migrationRequired, encryption, keychain(Int32), format }

@MainActor
final class EncryptedEiraStore: EiraStore {
    private struct Records: Codable {
        var entries: [Entry] = []
        var events: [Event] = []
        var draft: ReportDraft?
    }

    private let directory: URL
    private var secretURL: URL { directory.appendingPathComponent("records.sealed") }
    private var coverURL: URL { directory.appendingPathComponent("tasks.json") }
    private var records: Records?
    private var key: SymmetricKey?
    private var envelope: PrivateEncryption.Envelope?
    // The directory name stays stable when iOS moves the app's container after an update.
    private var keyAccount: String { directory.lastPathComponent }
    private(set) var sessionID = UUID()
    var isUnlocked: Bool { key != nil && records != nil }
    var needsSetup: Bool { !FileManager.default.fileExists(atPath: secretURL.path) }

    init(directory: URL = URL.applicationSupportDirectory.appendingPathComponent("Eira", isDirectory: true)) {
        self.directory = directory
    }

    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var location = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try location.setResourceValues(values)
    }

    private func write(_ data: Data, to url: URL) throws {
        try prepareDirectory()
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    func open() throws {
        lock()
        if needsSetup {
            try saveWithDeviceKey(Records(), key: SymmetricKey(size: .bits256))
            return
        }
        let envelope = try JSONDecoder().decode(PrivateEncryption.Envelope.self, from: Data(contentsOf: secretURL))
        if envelope.version == 1 { throw StoreError.migrationRequired }
        guard envelope.version == 2, envelope.salt.isEmpty, envelope.rounds == 0,
              envelope.wrappedKey.isEmpty else { throw StoreError.format }
        let key = try DeviceKeyStore.load(account: keyAccount)
        let records = try JSONDecoder().decode(Records.self,
            from: PrivateEncryption.open(envelope.ciphertext, key: key))
        self.key = key
        self.records = records
        self.envelope = envelope
        sessionID = UUID()
    }

    func migrate(passphrase: String) async throws {
        do {
            try await unlock(passphrase: passphrase)
            try Task.checkCancellation()
            guard let records, let key else { throw StoreError.locked }
            try saveWithDeviceKey(records, key: key)
        } catch { lock(); throw error }
    }

    private func saveWithDeviceKey(_ records: Records, key: SymmetricKey) throws {
        let envelope = PrivateEncryption.Envelope(version: 2, salt: Data(), rounds: 0,
            wrappedKey: Data(), ciphertext: try PrivateEncryption.seal(JSONEncoder().encode(records), key: key))
        try DeviceKeyStore.save(key, account: keyAccount)
        do { try write(JSONEncoder().encode(envelope), to: secretURL) }
        catch { try? DeviceKeyStore.delete(account: keyAccount); throw error }
        self.records = records
        self.key = key
        self.envelope = envelope
        sessionID = UUID()
    }

    func setup(passphrase: String) async throws {
        guard needsSetup else { throw StoreError.alreadyCreated }
        guard !passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw StoreError.invalidPassphrase }
        let attempt = sessionID
        let salt = try PrivateEncryption.salt()
        let wrappingKey = try await Task.detached {
            try PrivateEncryption.passwordKey(passphrase, salt: salt)
        }.value
        try Task.checkCancellation()
        guard attempt == sessionID else { throw StoreError.locked }
        guard needsSetup else { throw StoreError.alreadyCreated }
        let key = SymmetricKey(size: .bits256)
        let wrapped = try key.withUnsafeBytes { try PrivateEncryption.seal(Data($0), key: wrappingKey) }
        let empty = Records()
        let envelope = PrivateEncryption.Envelope(version: 1, salt: salt, rounds: PrivateEncryption.rounds,
            wrappedKey: wrapped, ciphertext: try PrivateEncryption.seal(JSONEncoder().encode(empty), key: key))
        try write(JSONEncoder().encode(envelope), to: secretURL)
        self.key = key
        self.records = empty
        self.envelope = envelope
        sessionID = UUID()
    }

    func unlock(passphrase: String) async throws {
        lock()
        let attempt = sessionID
        guard !needsSetup else { throw StoreError.missing }
        let envelope = try JSONDecoder().decode(PrivateEncryption.Envelope.self, from: Data(contentsOf: secretURL))
        guard envelope.version == 1, envelope.salt.count == 32, envelope.rounds == PrivateEncryption.rounds else {
            throw StoreError.format
        }
        let wrappingKey = try await Task.detached {
            try PrivateEncryption.passwordKey(passphrase, salt: envelope.salt)
        }.value
        try Task.checkCancellation()
        guard attempt == sessionID else { throw StoreError.locked }
        let key: SymmetricKey
        let decoded: Records
        do {
            var bytes = try PrivateEncryption.open(envelope.wrappedKey, key: wrappingKey)
            defer { bytes.resetBytes(in: 0..<bytes.count) }
            key = SymmetricKey(data: bytes)
            decoded = try JSONDecoder().decode(Records.self,
                from: PrivateEncryption.open(envelope.ciphertext, key: key))
        } catch { throw StoreError.invalidPassphrase }
        self.key = key
        self.records = decoded
        self.envelope = envelope
        sessionID = UUID()
    }

    func lock() {
        sessionID = UUID()
        key = nil
        records = nil
        envelope = nil
    }

    func checkSession(_ id: UUID) throws {
        guard isUnlocked, sessionID == id else { throw StoreError.locked }
    }

    private func read() throws -> Records {
        guard let records, isUnlocked else { throw StoreError.locked }
        return records
    }

    private func save(_ updated: Records) throws {
        guard let key, var envelope else { throw StoreError.locked }
        envelope.ciphertext = try PrivateEncryption.seal(JSONEncoder().encode(updated), key: key)
        try write(JSONEncoder().encode(envelope), to: secretURL)
        records = updated
        self.envelope = envelope
    }

    func entries() throws -> [Entry] { try read().entries }
    func events() throws -> [Event] { try read().events }
    func reportDraft() throws -> ReportDraft? { try read().draft }

    func saveEntry(_ entry: Entry) throws {
        var updated = try read()
        if let index = updated.entries.firstIndex(where: { $0.id == entry.id }) { updated.entries[index] = entry }
        else { updated.entries.append(entry) }
        try save(updated)
    }

    func deleteEntry(id: UUID) throws {
        var updated = try read()
        updated.entries.removeAll { $0.id == id }
        updated.events.removeAll { $0.entryID == id }
        updated.draft = updated.draft.map { draft in
            ReportDraft(fields: draft.fields.map { field in
                field.sourceEntryID == id && field.status != .editedByHer
                    ? ReportDraftField(fieldName: field.fieldName) : field
            })
        }
        try save(updated)
    }

    func saveEvents(_ events: [Event], for entryID: UUID) throws {
        var updated = try read()
        guard let entry = updated.entries.first(where: { $0.id == entryID }) else { throw StoreError.missing }
        updated.events.removeAll { $0.entryID == entryID }
        updated.events.append(contentsOf: events.compactMap { QuoteCheck.validated($0, against: entry) })
        try save(updated)
    }

    func saveReportDraft(_ draft: ReportDraft) throws {
        var updated = try read()
        updated.draft = draft
        try save(updated)
    }

    func coverTasks() throws -> [CoverTask] {
        guard FileManager.default.fileExists(atPath: coverURL.path) else { return [] }
        return try JSONDecoder().decode([CoverTask].self, from: Data(contentsOf: coverURL))
    }

    func saveCoverTask(_ task: CoverTask) throws {
        guard task.title != "eira" else { throw StoreError.format }
        var tasks = try coverTasks()
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { tasks[index] = task }
        else { tasks.append(task) }
        try write(JSONEncoder().encode(tasks), to: coverURL)
    }

    func deleteCoverTask(id: UUID) throws {
        let tasks = try coverTasks().filter { $0.id != id }
        try write(JSONEncoder().encode(tasks), to: coverURL)
    }

    func deleteSecretData() throws {
        lock()
        try DeviceKeyStore.delete(account: keyAccount)
        if !needsSetup { try FileManager.default.removeItem(at: secretURL) }
    }
}

// Bind all private consumers to one unlock; old requests cannot write into a new session.
@MainActor
final class PrivateSessionStore: EiraStore {
    private let store: EncryptedEiraStore
    private let id: UUID
    init(_ store: EncryptedEiraStore) { self.store = store; id = store.sessionID }
    func entries() async throws -> [Entry] { try store.checkSession(id); return try store.entries() }
    func saveEntry(_ entry: Entry) async throws { try store.checkSession(id); try store.saveEntry(entry) }
    func deleteEntry(id entryID: UUID) async throws { try store.checkSession(id); try store.deleteEntry(id: entryID) }
    func events() async throws -> [Event] { try store.checkSession(id); return try store.events() }
    func saveEvents(_ events: [Event], for entryID: UUID) async throws {
        try store.checkSession(id); try store.saveEvents(events, for: entryID)
    }
    func reportDraft() async throws -> ReportDraft? { try store.checkSession(id); return try store.reportDraft() }
    func saveReportDraft(_ draft: ReportDraft) async throws { try store.checkSession(id); try store.saveReportDraft(draft) }
    func coverTasks() async throws -> [CoverTask] { try store.checkSession(id); return try store.coverTasks() }
    func saveCoverTask(_ task: CoverTask) async throws { try store.checkSession(id); try store.saveCoverTask(task) }
    func deleteCoverTask(id taskID: UUID) async throws { try store.checkSession(id); try store.deleteCoverTask(id: taskID) }
    func deleteSecretData() async throws { try store.checkSession(id); try store.deleteSecretData() }
}
