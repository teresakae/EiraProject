import Foundation

// Invented fixture text only. No network, FAQ files, prompt or schema is loaded.
struct CannedServerClient: ServerClient {
    static let sampleEntryText = "Tadi pagi dia ngelempar piring ke arahku, kena lenganku, memar biru sampe sekarang."

    func extract(_ request: ExtractRequest) async throws -> ExtractResponse {
        let sample = ExtractedEvent(whenText: "Tadi pagi", whatHappened: Self.sampleEntryText,
                                    injuries: "memar biru sampe sekarang", witnesses: [],
                                    quote: Self.sampleEntryText, violenceType: .physical)
        // A fixed fixture must never attach invented events to a different input.
        let isSample = request.text == Self.sampleEntryText
        return ExtractResponse(events: isSample ? [sample] : [],
                               coverTask: "Tidy the desk",
                               reply: isSample ? "You said your arm is still bruised. Would you like to say more?"
                                               : "I could not process this entry yet.")
    }

    func ask(_ request: AskRequest) async throws -> AskResponse {
        AskResponse(answer: "I cannot answer this legal question yet. You can ask LBH APIK directly.",
                    faqAnswersUsed: [], articlesNamed: [], notSure: true)
    }

    func talk(_ request: TalkRequest) async throws -> TalkResponse {
        if request.message?.hasSuffix("?") == true {
            return TalkResponse(reply: "", isLegalQuestion: true, quickReplies: [], facts: [])
        }
        let hasSample = request.entries.contains { $0.text == Self.sampleEntryText }
        return TalkResponse(
            reply: request.message == nil ? "Where were you when this happened?" : "Did anyone else see or hear it?",
            isLegalQuestion: false,
            quickReplies: request.message == nil ? [] : ["Yes", "No one"],
            facts: hasSample ? [.init(category: .when, value: "This morning", quote: "Tadi pagi"),
                                .init(category: .what, value: "A plate thrown, bruising your arm", quote: "ngelempar piring")] : [])
    }

    func draft(_ request: DraftRequest) async throws -> DraftResponse {
        var fields = Dictionary(uniqueKeysWithValues: ReportFieldName.allCases.map {
            ($0, DraftFieldResponse(value: nil, quote: nil))
        })
        if request.entries.contains(Self.sampleEntryText) {
            fields[.description] = DraftFieldResponse(value: .text(Self.sampleEntryText), quote: Self.sampleEntryText)
        }
        return DraftResponse(fields: fields)
    }

    func transcribe(_ request: TranscribeRequest) async throws -> String {
        Self.sampleEntryText
    }
}
