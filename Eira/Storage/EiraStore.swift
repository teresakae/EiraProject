import Foundation

@MainActor
protocol EiraStore: AnyObject {
    func entries() async throws -> [Entry]
    func saveEntry(_ entry: Entry) async throws
    func deleteEntry(id: UUID) async throws
    func events() async throws -> [Event]
    func saveEvents(_ events: [Event], for entryID: UUID) async throws
    func reportDraft() async throws -> ReportDraft?
    func saveReportDraft(_ draft: ReportDraft) async throws
    func talkFacts() async throws -> [TalkFact]
    func saveTalkFacts(_ facts: [TalkFact]) async throws
    func coverTasks() async throws -> [CoverTask]
    func saveCoverTask(_ task: CoverTask) async throws
    func deleteCoverTask(id: UUID) async throws
    func deleteSecretData() async throws
}
