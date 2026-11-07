import Foundation

protocol ServerClient: Sendable {
    func cancelPendingRequests()
    func extract(_ request: ExtractRequest) async throws -> ExtractResponse
    func ask(_ request: AskRequest) async throws -> AskResponse
    func talk(_ request: TalkRequest) async throws -> TalkResponse
    func draft(_ request: DraftRequest) async throws -> DraftResponse
    func transcribe(_ request: TranscribeRequest) async throws -> String
}

extension ServerClient {
    func cancelPendingRequests() { }
    // A client without the talk call treats every message as a question for the Ask route.
    func talk(_ request: TalkRequest) async throws -> TalkResponse {
        TalkResponse(reply: "", isLegalQuestion: true, quickReplies: [], facts: [])
    }
}

struct ExtractRequest: Codable, Equatable, Sendable {
    let text: String
}

// Wire events have no local identity, entry ID or user-edit marker.
struct ExtractedEvent: Codable, Equatable, Sendable {
    let whenText: String?
    let whatHappened: String
    let injuries: String?
    let witnesses: [String]
    let quote: String
    let violenceType: ViolenceType

    init(whenText: String?, whatHappened: String, injuries: String?, witnesses: [String],
         quote: String, violenceType: ViolenceType) {
        self.whenText = whenText
        self.whatHappened = whatHappened
        self.injuries = injuries
        self.witnesses = witnesses
        self.quote = quote
        self.violenceType = violenceType
    }

    init(_ event: Event) {
        self.init(whenText: event.whenText, whatHappened: event.whatHappened,
                  injuries: event.injuries, witnesses: event.witnesses,
                  quote: event.quote, violenceType: event.violenceType)
    }

    func event(for entry: Entry) -> Event? {
        QuoteCheck.validated(Event(entryID: entry.id, whenText: whenText, whatHappened: whatHappened,
                                   injuries: injuries, witnesses: witnesses, quote: quote,
                                   violenceType: violenceType), against: entry)
    }

    enum CodingKeys: String, CodingKey {
        case injuries, witnesses, quote
        case whenText = "when_text"
        case whatHappened = "what_happened"
        case violenceType = "pkdrt_type"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(whenText, forKey: .whenText)
        try container.encode(whatHappened, forKey: .whatHappened)
        try container.encode(injuries, forKey: .injuries)
        try container.encode(witnesses, forKey: .witnesses)
        try container.encode(quote, forKey: .quote)
        try container.encode(violenceType, forKey: .violenceType)
    }
}

struct ExtractResponse: Codable, Equatable, Sendable {
    let events: [ExtractedEvent]
    let coverTask: String
    let reply: String

    enum CodingKeys: String, CodingKey {
        case events, reply
        case coverTask = "cover_task"
    }
}

struct AskMessage: Codable, Equatable, Sendable {
    enum Role: String, Codable, Sendable { case user, assistant }
    let role: Role
    let text: String
}

struct AskContextEntry: Codable, Equatable, Sendable {
    let text: String
    let events: [ExtractedEvent]
}

struct AskRequest: Encodable, Equatable, Sendable {
    let question: String
    let conversation: [AskMessage]
    let entries: [AskContextEntry]

    init(question: String, conversation: [AskMessage], entries: [Entry], events: [Event]) {
        self.question = question
        self.conversation = conversation
        self.entries = entries.filter { $0.allowedUses.legalGuidance }.map { entry in
            AskContextEntry(text: entry.text, events: events.filter { $0.entryID == entry.id }.map(ExtractedEvent.init))
        }
    }
}

struct AskResponse: Codable, Equatable, Sendable {
    let answer: String
    let faqAnswersUsed: [Int]
    let articlesNamed: [String]
    let notSure: Bool

    enum CodingKeys: String, CodingKey {
        case answer
        case faqAnswersUsed = "faq_answers_used"
        case articlesNamed = "articles_named"
        case notSure = "not_sure"
    }
}

struct TalkRequest: Encodable, Equatable, Sendable {
    let message: String?
    let conversation: [AskMessage]
    let entries: [AskContextEntry]

    init(message: String?, conversation: [AskMessage], entries: [Entry], events: [Event]) {
        self.message = message
        self.conversation = conversation
        self.entries = entries.filter { $0.allowedUses.legalGuidance }.map { entry in
            AskContextEntry(text: entry.text, events: events.filter { $0.entryID == entry.id }.map(ExtractedEvent.init))
        }
    }

    enum CodingKeys: String, CodingKey { case message, conversation, entries }

    // The server requires the key, so an empty message is sent as an explicit null.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(conversation, forKey: .conversation)
        try container.encode(entries, forKey: .entries)
    }
}

struct TalkFactResponse: Codable, Equatable, Sendable {
    let category: TalkFactCategory
    let value: String
    let quote: String
}

struct TalkResponse: Codable, Equatable, Sendable {
    let reply: String
    let isLegalQuestion: Bool
    let quickReplies: [String]
    let facts: [TalkFactResponse]

    enum CodingKeys: String, CodingKey {
        case reply, facts
        case isLegalQuestion = "is_legal_question"
        case quickReplies = "quick_replies"
    }
}

struct DraftRequest: Encodable, Equatable, Sendable {
    let entries: [String]
    let questions: [String]

    init(entries: [Entry]) {
        let allowed = entries.filter { $0.allowedUses.report }
        self.entries = allowed.filter { $0.kind == .story }.map(\.text)
        self.questions = allowed.filter { $0.kind != .story }.map(\.text)
    }
}

struct DraftFieldResponse: Codable, Equatable, Sendable {
    let value: ReportValue?
    let quote: String?

    enum CodingKeys: String, CodingKey { case value, quote }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(quote, forKey: .quote)
    }
}

struct DraftResponse: Codable, Equatable, Sendable {
    let fields: [ReportFieldName: DraftFieldResponse]

    init(fields: [ReportFieldName: DraftFieldResponse]) { self.fields = fields }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FieldKey.self)
        var fields: [ReportFieldName: DraftFieldResponse] = [:]
        for name in ReportFieldName.allCases {
            fields[name] = try container.decode(DraftFieldResponse.self, forKey: FieldKey(name))
        }
        self.fields = fields
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FieldKey.self)
        for name in ReportFieldName.allCases {
            try container.encode(fields[name] ?? DraftFieldResponse(value: nil, quote: nil), forKey: FieldKey(name))
        }
    }

    private struct FieldKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(_ name: ReportFieldName) { stringValue = name.rawValue }
        init?(stringValue: String) {
            guard ReportFieldName(rawValue: stringValue) != nil else { return nil }
            self.stringValue = stringValue
        }
        init?(intValue: Int) { return nil }
    }
}

struct TranscribeRequest: Sendable {
    let audio: Data
    let filename: String
    let contentType: String
    let language = "id"
}
