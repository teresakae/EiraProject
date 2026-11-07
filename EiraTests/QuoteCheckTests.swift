import XCTest
@testable import Eira

final class QuoteCheckTests: XCTestCase {
    private let text = "Semalam sekitar jam 11, pipiku masih bengkak."

    func testQ2CorruptedQuoteIsRejectedAndFieldCleared() {
        let entry = Entry(text: text)
        let corrupted = "pipiku masih berdarah"
        XCTAssertFalse(QuoteCheck.contains(corrupted, in: text))
        let field = ReportDraftField(fieldName: .description, value: .text(corrupted),
                                     quote: corrupted, sourceEntryID: entry.id, status: .fromHerWords)
        let checked = QuoteCheck.validated(field, against: [entry])
        XCTAssertNil(checked.value)
        XCTAssertNil(checked.quote)
        XCTAssertNil(checked.sourceEntryID)
        XCTAssertEqual(checked.status, .empty)
        let event = Event(entryID: entry.id, whenText: nil, whatHappened: corrupted,
                          injuries: nil, witnesses: [], quote: corrupted, violenceType: .unsure)
        XCTAssertNil(QuoteCheck.validated(event, against: entry))
    }

    func testQ3CapitalLettersAndMissingCommaAreAccepted() {
        let entry = Entry(text: text)
        for quote in ["PIPIKU MASIH BENGKAK", "Semalam sekitar jam 11 pipiku masih bengkak"] {
            XCTAssertTrue(QuoteCheck.contains(quote, in: text))
            let field = ReportDraftField(fieldName: .description, value: .text(quote), quote: quote)
            let checked = QuoteCheck.validated(field, against: [entry])
            XCTAssertEqual(checked.sourceEntryID, entry.id)
            XCTAssertEqual(checked.status, .fromHerWords)
        }
    }

    func testQ6EmptyAndPunctuationOnlyQuotesAreRejected() {
        for quote in [nil, "", " \n\t ", "... ,!?", "\u{201C}\u{201D}\u{2018}\u{2019}—"] as [String?] {
            XCTAssertFalse(QuoteCheck.contains(quote, in: text))
            let checked = QuoteCheck.validated(
                ReportDraftField(fieldName: .description, value: .text("invented"), quote: quote),
                against: [Entry(text: text)])
            XCTAssertNil(checked.value)
            XCTAssertNil(checked.quote)
        }
    }

    func testCompatibilityUnicodeCurlyQuotesAndWhitespace() {
        XCTAssertTrue(QuoteCheck.contains("jam 11 aku bilang tidak", in: "ＪＡＭ １１\naku\tbilang ‘tidak’."))
        XCTAssertFalse(QuoteCheck.contains("bengkaknya", in: text))
    }

    func testSourceMustBeOneAllowedEntryAndQuestionsCanBeSources() {
        let restricted = Entry(text: text, allowedUses: AllowedUses(personalTimeline: true, legalGuidance: true, report: false))
        let field = ReportDraftField(fieldName: .description, value: .text("bengkak"), quote: "pipiku masih bengkak")
        XCTAssertNil(QuoteCheck.validated(field, against: [restricted]).value)
        XCTAssertNil(QuoteCheck.validated(field, against: [Entry(text: "pipiku masih"), Entry(text: "bengkak")]).value)
        let question = Entry(text: text, kind: .question)
        XCTAssertEqual(QuoteCheck.validated(field, against: [question]).sourceEntryID, question.id)
    }

    func testHerEditIsPreservedWithoutAIQuote() {
        let field = ReportDraftField(fieldName: .provinceCity, value: .text("Bekasi"), status: .editedByHer)
        XCTAssertEqual(QuoteCheck.validated(field, against: []), field)
    }
}
