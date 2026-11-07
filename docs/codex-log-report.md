# Ask and Report work log

Date: 7 Nov 2026. Owner: Person C.

## Requested and approved scope

Build the Ask chat, Report draft and review, draft confirmation and privacy copy in one strings file, a bundled mock form, non-persistent in-app form filling, and per-field copy. Continue using `CannedServerClient` and `InMemoryEiraStore`. Do not change the server, cover, Write, storage, or shared models. Never submit test data to the real form.

Read `AGENTS.md`, `BRIEF.md`, `PRODUCT.md`, `ARCHITECTURE.md`, `SAPA_FORM.md`, `SAFETY.md`, the Ask/draft/quote-check contracts, and `FIXTURES.md`. No FAQ content files were read, copied, or bundled.

Read the live form at `https://laporsapa129.kemenpppa.go.id/lapor` without entering data. The page exposes Back/Continue controls and a location selector, so the initial work stopped as requested. The owner then approved the proposed mock-only implementation using `SAPA_FORM.md`, with real-form filling deferred. No real form inputs, transitions, or submission were exercised.

No git operations that change state were performed. The owner's standing instruction reserves branches and commits to the owner; this work stays in the supplied working folder. Existing changes under `server/` belong to other work and were left alone.

## Built

- `AskScreen(dependencies:)` and `AskFlow`: exact questions saved as question entries, allowed legal context and events only, filtered conversation, ordinary canned hand-off replies, retry without duplicating saved questions, and a visible plain-code caveat for FAQ IDs 4, 7, or 11. Assistant replies stay in session memory and never become entries or quote sources. Replies that depended on a now-restricted or deleted entry are removed from subsequent context.
- `ReportScreen(dependencies:)`, `ReportFlow`, and `ReportFields`: all 17 fields, exact dropdown lists, age/boolean/phone/text validation, quote validation and source IDs through the existing `QuoteCheck`, three visible states, editing and intentional clearing preserved across refresh/reopening, required-field flags, and rechecking permissions after an asynchronous draft call and before confirmation/form/copy.
- `SafetyStrings.swift`: Indonesian draft confirmation, privacy copy, and caveat. The privacy text explicitly identifies the current in-memory/canned build before describing the planned AI/encrypted-storage flow, so it does not claim this build is encrypted.
- `ReportFormWebView.swift` and bundled `MockReportForm.html`: non-persistent WebKit storage, all 17 controls filled as data rather than executable text, no network connections or form action permitted, and no automatic submit/click code in the app. Only the local form's own submit handler displays a receipt. A real target fails closed to the copy fallback while real mapping is deferred.
- Per-field copy uses the current, rechecked draft. The system clipboard exposure remains unverified, as recorded in `PRODUCT.md`.
- New XCTest coverage includes the actual bundled HTML in WebKit, receipt values, non-persistent storage, network blocking, edited and empty values, field validation, allowed-use changes, confirmation gating, failure/retry behavior, and UI captures.

## Integration

The app still mounts only the cover. This slice deliberately does not change `EiraApp`, `AppDependencies`, cover/access handling, Write, store implementations, shared models, build settings, or dependencies. Person B/the owner connects the screens inside the secret area with the same `AppDependencies` instance. `AskFlow` may also be retained by the secret-area owner and passed to `AskScreen(flow:)` to keep session replies across screen recreation. Existing question entries and the report draft are read through the shared store.

Privacy copy must be updated here when the owner replaces the canned client or in-memory store. Real-form mapping and autosave behavior remain unresolved; no real form URL is present in this slice's app code. Release's existing `real` setting is unchanged and therefore shows the unavailable/copy path until that work is approved and implemented.

## Verification

Xcode 27.2; separate iPhone 17e simulator, iOS 26.5, ID `9DF463FA-F257-47F8-9934-7ECA1F4AD47A`. Derived data: `.build/ReportDerivedData`. Only invented text and test phone numbers were used.

Final results: **29 tests passed, 0 failed** in each configuration below. Captured Ask caveat, review, confirmation, mock controls/receipt, and large-text source layout were inspected. One intermediate screenshot-check build failed because the WebKit capture call used the wrong argument label; it was corrected before these final runs.

- Debug with `EIRA_REPORT_TARGET=real`: still forced to mock, all 29 tests pass. Result: `.build/ReportDerivedData/Logs/Test/Test-Eira-2026.11.07_11-18-38-+0700.xcresult`.
- Release with `EIRA_RELEASE_REPORT_TARGET=mock`: all 29 tests pass. Result: `.build/ReportDerivedData/Logs/Test/Test-Eira-2026.11.07_11-19-07-+0700.xcresult`.
- `git diff --check`: passed. Existing unrelated changes were left untouched.

Reproduce from the repository root (the Release override is mandatory for this mock-only check):

```sh
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug \
  -destination 'platform=iOS Simulator,id=9DF463FA-F257-47F8-9934-7ECA1F4AD47A' \
  -derivedDataPath .build/ReportDerivedData -parallel-testing-enabled NO \
  EIRA_REPORT_TARGET=real CODE_SIGNING_ALLOWED=NO test

xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Release \
  -destination 'platform=iOS Simulator,id=9DF463FA-F257-47F8-9934-7ECA1F4AD47A' \
  -derivedDataPath .build/ReportDerivedData -parallel-testing-enabled NO \
  EIRA_RELEASE_REPORT_TARGET=mock CODE_SIGNING_ALLOWED=NO test
```

| Fixture | Result and evidence |
|---|---|
| U1 | PASS: restricted entry absent from draft request and draft; saved sourced fields cleared when permission changes; checked again after a pending request. |
| U2 | PASS: restricted stories, questions, and events excluded from Ask; prior assistant context discarded after a source restriction. |
| V1 | PASS: plain-code caveat for each of 4, 7, and 11, absent for other IDs; invented response used for UI capture. No FAQ files loaded. |
| S1 | PASS on mock: receipt is empty after filling; only a test simulation of her press on the bundled mock button creates a receipt. No production code presses send or invokes submission. |
| S2 | PASS for Debug's forced-mock behavior and fail-closed real target. Release-with-mock build also passes. Actual demo-branch check is NOT RUN: no branch was created or modified. |
| S3 | PASS: all 17 controls and receipt values match the known draft, including edits, booleans, age, empty values, and text containing quotes/newlines/HTML. |
| CF1 | PASS: form cannot open before confirmation; confirmation carries values, quotes, recipient, risks, unknowns, anonymity and her control; changed permissions invalidate confirmation. |
| N1 | PASS for this app slice and canned hand-off: review/confirmation/Ask copy has no reporting nudge or progress count. Full-app and future real AI output review belongs to integration. |
| Q1 | PASS: invented value/quote rejected in five runs, plus unsupported quotes rejected for every one of the 17 fields. These are deterministic client checks, not live model runs. |
| Q4 | PASS with canned responses: concern stays empty for M1. Real model paraphrase behavior remains untested. |
| Q5 | PASS with canned responses and invented-pair checks: no unsupported name added. Real model behavior remains untested. |

Existing Q2, Q3, Q6 and base-contract checks also passed. No physical iPhone, real API, real intake, live dropdown mapping, autosave, or actual demo branch was tested. Draft Indonesian copy still needs the team's wording review.
