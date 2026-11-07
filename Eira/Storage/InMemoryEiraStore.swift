import Foundation

// Stand-in only: no persistence or encryption. Replace in phase 2.
@MainActor
final class InMemoryEiraStore: EiraStore {
    private var storedEntries: [Entry] = []
    private var storedEvents: [Event] = []
    private var storedDraft: ReportDraft?
    private var storedTasks: [CoverTask] = []

    func entries() async throws -> [Entry] { storedEntries }

    func saveEntry(_ entry: Entry) async throws {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries[index] = entry
        } else {
            storedEntries.append(entry)
        }
    }

    func deleteEntry(id: UUID) async throws {
        storedEntries.removeAll { $0.id == id }
        storedEvents.removeAll { $0.entryID == id }
        storedDraft = storedDraft.map { draft in
            ReportDraft(fields: draft.fields.map { field in
                field.sourceEntryID == id && field.status != .editedByHer
                    ? ReportDraftField(fieldName: field.fieldName) : field
            })
        }
    }

    func events() async throws -> [Event] { storedEvents }

    func saveEvents(_ events: [Event], for entryID: UUID) async throws {
        storedEvents.removeAll { $0.entryID == entryID }
        storedEvents.append(contentsOf: events.filter { $0.entryID == entryID })
    }

    func reportDraft() async throws -> ReportDraft? { storedDraft }
    func saveReportDraft(_ draft: ReportDraft) async throws { storedDraft = draft }
    func coverTasks() async throws -> [CoverTask] { storedTasks }

    func saveCoverTask(_ task: CoverTask) async throws {
        if let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            storedTasks[index] = task
        } else {
            storedTasks.append(task)
        }
    }

    func deleteCoverTask(id: UUID) async throws { storedTasks.removeAll { $0.id == id } }

    func deleteSecretData() async throws {
        storedEntries.removeAll()
        storedEvents.removeAll()
        storedDraft = nil
    }
}
