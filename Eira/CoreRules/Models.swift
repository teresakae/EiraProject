import Foundation

struct AllowedUses: Codable, Equatable, Sendable {
    var personalTimeline: Bool
    var legalGuidance: Bool
    var report: Bool

    enum CodingKeys: String, CodingKey {
        case personalTimeline = "personal_timeline"
        case legalGuidance = "legal_guidance"
        case report
    }
}

enum EntrySource: String, Codable, Sendable {
    case text, voice
    // Suggested wording she tapped. Never a quote source for noted facts.
    case quickReply = "quick_reply"
}

enum EntryKind: String, Codable, Sendable {
    // A correction holds her own wording from fixing a noted fact.
    case story, question, correction
}

struct Entry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    let text: String
    let source: EntrySource
    let kind: EntryKind
    var allowedUses: AllowedUses
    // AI text stays separate from her immutable words and is never a quote source.
    var writeReply: String?
    // Eira's answer to a question, with the entries it drew on. Only shown while they all stay allowed.
    var talkAnswer: AskResponse?
    var talkAnswerSources: [UUID]?

    init(id: UUID = UUID(), createdAt: Date = Date(), text: String,
         source: EntrySource = .text, kind: EntryKind = .story,
         allowedUses: AllowedUses = EntryUseDefaults.allowedUses) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.source = source
        self.kind = kind
        self.allowedUses = allowedUses
    }

    enum CodingKeys: String, CodingKey {
        case id, text, source, kind
        case createdAt = "created_at"
        case allowedUses = "allowed_uses"
        case writeReply = "write_reply"
        case talkAnswer = "talk_answer"
        case talkAnswerSources = "talk_answer_sources"
    }

    // An answer can repeat a deleted entry's details, so it goes with that entry.
    func removingAnswer(drawnFrom id: UUID) -> Entry {
        guard talkAnswerSources?.contains(id) == true else { return self }
        var updated = self
        updated.talkAnswer = nil
        updated.talkAnswerSources = nil
        return updated
    }
}

enum ViolenceType: String, Codable, Sendable {
    case physical = "fisik"
    case psychological = "psikis"
    case sexual = "seksual"
    case neglect = "penelantaran"
    case unsure = "tidak_yakin"
}

struct Event: Identifiable, Codable, Equatable, Sendable {
    // Local identity lets several events belong to one entry.
    let id: UUID
    let entryID: UUID
    var whenText: String?
    var whatHappened: String
    var injuries: String?
    var witnesses: [String]
    var quote: String
    var violenceType: ViolenceType
    var userEdited: Bool

    init(id: UUID = UUID(), entryID: UUID, whenText: String?, whatHappened: String,
         injuries: String?, witnesses: [String], quote: String,
         violenceType: ViolenceType, userEdited: Bool = false) {
        self.id = id
        self.entryID = entryID
        self.whenText = whenText
        self.whatHappened = whatHappened
        self.injuries = injuries
        self.witnesses = witnesses
        self.quote = quote
        self.violenceType = violenceType
        self.userEdited = userEdited
    }

    enum CodingKeys: String, CodingKey {
        case id, injuries, witnesses, quote
        case entryID = "entry_id"
        case whenText = "when_text"
        case whatHappened = "what_happened"
        case violenceType = "pkdrt_type"
        case userEdited = "user_edited"
    }
}

enum TalkFactCategory: String, CaseIterable, Codable, Sendable {
    case who, what, when, `where`
}

struct TalkFact: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let category: TalkFactCategory
    var value: String
    var quote: String?
    var sourceEntryID: UUID?
    var userEdited: Bool

    init(id: UUID = UUID(), category: TalkFactCategory, value: String, quote: String?,
         sourceEntryID: UUID?, userEdited: Bool = false) {
        self.id = id
        self.category = category
        self.value = value
        self.quote = quote
        self.sourceEntryID = sourceEntryID
        self.userEdited = userEdited
    }

    enum CodingKeys: String, CodingKey {
        case id, category, value, quote
        case sourceEntryID = "source_entry_id"
        case userEdited = "user_edited"
    }
}

enum ReportFieldName: String, CaseIterable, Codable, Sendable {
    case isVictim = "is_victim"
    case levelConcern = "level_concern"
    case relationshipWithVictim = "relationship_with_victim"
    case incidentTime = "incident_time"
    case location
    case provinceCity = "province_city"
    case description
    case victimFullName = "korban_fullname"
    case victimGender = "korban_gender"
    case victimAge = "korban_age"
    case victimDisabilities = "korban_disabilities"
    case victimDisabilitiesType = "korban_disabilities_type"
    case victimContactNumber = "korban_contact_number"
    case victimTrustedPerson = "korban_trusted_person"
    case reporterFullName = "reporter_fullname"
    case anonymous
    case contactNumber = "contact_number"
}

// The wire value stays a JSON string, integer or boolean, never a tagged object.
enum ReportValue: Codable, Equatable, Sendable {
    case text(String)
    case integer(Int)
    case boolean(Bool)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else {
            self = .text(try container.decode(String.self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .boolean(let value): try container.encode(value)
        }
    }
}

enum ReportFieldStatus: String, Codable, Sendable {
    case empty
    case fromHerWords = "from her words"
    case editedByHer = "edited by her"
}

struct ReportDraftField: Identifiable, Codable, Equatable, Sendable {
    var id: ReportFieldName { fieldName }
    let fieldName: ReportFieldName
    var value: ReportValue?
    var quote: String?
    var sourceEntryID: UUID?
    var status: ReportFieldStatus

    init(fieldName: ReportFieldName, value: ReportValue? = nil, quote: String? = nil,
         sourceEntryID: UUID? = nil, status: ReportFieldStatus = .empty) {
        self.fieldName = fieldName
        self.value = value
        self.quote = quote
        self.sourceEntryID = sourceEntryID
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case value, quote, status
        case fieldName = "field_name"
        case sourceEntryID = "source_entry_id"
    }
}

struct ReportDraft: Codable, Equatable, Sendable {
    var fields: [ReportDraftField]

    init(fields: [ReportDraftField] = ReportFieldName.allCases.map { ReportDraftField(fieldName: $0) }) {
        self.fields = fields
    }
}

struct CoverTask: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    let createdAt: Date
    var isCompleted: Bool
    var body: String?
    var isPinned: Bool?
    var checklist: [CoverChecklistItem]?

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id, title, body, checklist
        case isPinned = "is_pinned"
        case createdAt = "created_at"
        case isCompleted = "is_completed"
    }
}

struct CoverChecklistItem: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var text: String
    var isCompleted = false
}
