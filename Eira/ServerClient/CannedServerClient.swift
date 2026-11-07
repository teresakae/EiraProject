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
                               coverTask: "Rapikan meja",
                               reply: isSample ? "Kamu cerita lenganmu masih memar. Mau cerita lebih lanjut?"
                                               : "Aku belum bisa mengurai catatan ini.")
    }

    func ask(_ request: AskRequest) async throws -> AskResponse {
        AskResponse(answer: "Aku belum bisa menjawab pertanyaan hukum ini. Kamu bisa bertanya langsung ke LBH APIK.",
                    faqAnswersUsed: [], articlesNamed: [], notSure: true)
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
