# Eira: shared base log

7 Nov 2026 · Phase 0 only

**Status: complete. The app runs on the iPhone 17 Pro simulator, and all 13 tests pass in both Debug and Release under Xcode 27.2. Phase 0 stops here; no feature phase was started.**

## What was requested

Prepare the shared foundation for three parallel builders, without building features: a SwiftUI Xcode project using folder-synced groups; five layer folders and an empty `server/`; shared data models; a store interface with an in-memory stand-in; a server-client interface with canned extract, ask, draft and transcribe responses; the quote check with Q2, Q3 and Q6 tests; Debug/mock and Release/real report configuration; empty Cover, Write, Ask and Report screens; working commands and this log.

A subagent copied the 13 listed handoff files into `docs/` and verified every copy byte-for-byte. The owner approved the base implementation plan before project creation.

The owner then changed the disguise to a to-do list, with access by adding a task named exactly `eira`, and chose an unrelated cover task in place of each generated plant note. Those decisions are recorded in PRODUCT C11 and reflected in the active docs, architecture diagram and extract response (`cover_task`). The plant-name setup is removed. The fixed trigger is not an encryption secret; replacement key management remains OPEN for the later storage phase.

## What was built

- `Eira.xcodeproj`: app `Eira`, bundle ID `org.eira.app`, shared `Eira` scheme, iOS 17 minimum, Swift 6, no third-party dependencies. Both app and test sources use `PBXFileSystemSynchronizedRootGroup`.
- Layers under `Eira/`: `UI`, `CoreRules`, `Storage`, `ServerClient`, `PlatformServices`. `server/` exists and is empty; fresh checkouts may need to recreate this untracked empty directory.
- Models: entries with exact text, phone time, text/voice source, story/question kind and three allowed-use flags; events with entry references and editable suggestions; all 17 report fields with typed values, provenance and the three statuses; cover tasks without any entry link.
- `EntryUseDefaults`: the one PROVISIONAL all-on default. No entry-use UI was built.
- `EiraStore` and `InMemoryEiraStore`: main-actor async/throwing record access, with cover tasks retained when secret records are deleted. No persistence or encryption.
- `ServerClient`, typed requests/responses and `CannedServerClient`: four async/throwing calls. Extract returns an invented fixture event only for its exact sample text, an unrelated task title and an Indonesian reply. Ask uses invented hand-off text and no legal claims. Draft returns every field's value/quote pair, explicitly null when unknown. Transcription returns invented sample text. Ask/draft request builders filter entries by allowed uses.
- `QuoteCheck`: NFKC, lowercase, curly-quote replacement, punctuation removal, whitespace collapse, trim, non-empty substring check. Invalid events are dropped; unsupported AI fields are cleared; source IDs come from allowed entries checked one at a time. Her edits survive. Only her text can be a source.
- Report configuration: Debug is always mock, including a runtime guard. Release defaults to real through `Configuration/ReportTarget.xcconfig`; `Configuration/Info.plist` carries the selected value into the built app. The later demo branch can change that single Release value to mock. No real form URL or delivery implementation is present.
- Four independent empty screen files. `EiraApp` mounts only the cover. No task controls, access flow, chat, timeline, draft editor, encryption, server, prompts, audio handling or web view was built.
- `AGENTS.md`: owner rules, build/run/test commands, interface handoff and ownership boundaries.

## Verification so far

| Check | Result |
|---|---|
| Debug and Release app/test builds, Xcode 27.2 / iOS Simulator 26.5, SDK 27.2 | Passed |
| Folder-synced project support | Passed: app and tests compiled from synchronized roots without per-file project entries |
| Project-file format and shared scheme | Passed (`plutil` and XML parse) |
| Model names against SAPA_FORM | Passed: all 17 fields match |
| Base-only scope and empty server | Passed: four empty screens; no feature controls, network implementation, encryption, prompts or web view |
| Approved FAQ, legal docs, form spec and flow image | Passed: unchanged from the copied originals |
| Debug app installation, launch and visible cover | Passed: only the empty Eira cover is visible; screenshot inspected at `.build/cover-verified.png` |
| Q2: corrupted quote rejected, field cleared, event dropped | Passed in Debug and Release |
| Q3: capitalization / missing comma accepted, source recorded | Passed in Debug and Release |
| Q6: nil, empty, whitespace and punctuation-only quote rejected | Passed in Debug and Release |
| Remaining base contract tests | Passed: 13 total methods per configuration, zero failures |
| Built report targets | Passed: Debug metadata is `mock`, Release metadata is `real`; runtime tests pass in both configurations |

There are 13 XCTest methods across `QuoteCheckTests` and `BaseContractTests`. Besides Q2/Q3/Q6, they cover Unicode and whitespace, per-entry provenance, allowed-use filtering, preserving her edits, typed wire values, all 17 draft pairs and explicit nulls, invented canned replies/transcription, store deletion boundaries, defaults and report-target configuration.

Initial simulator attempts under Xcode 26.6 stopped before the runner connected. After the owner updated Xcode to 27.2 and completed setup, simulator execution succeeded. Release verification then caught a missing custom metadata key: the initial generated-plist setting did not reach the app bundle. This was fixed with an explicit `Configuration/Info.plist`, and the existing configuration test now requires the key in both builds. Both complete suites passed after that fix. No simulator reset or unrelated system changes were made.

Final test results are in `.build/DebugVerified.xcresult` and `.build/ReleaseVerified.xcresult` (local, ignored build artifacts). Commands are documented in `AGENTS.md`. No live endpoint or real form was contacted.

## What parallel builders can rely on

1. Add source files inside the app or test tree without editing `project.pbxproj`.
2. Use the shared models in `CoreRules/Models.swift`; after this base, only Person B changes them.
3. Use `EiraStore` and `ServerClient`; swap their stand-ins through `AppDependencies` at integration.
4. Use the central allowed-use default and quote checker. Field-type/dropdown validation remains part of the later Report slice.
5. Expect `events`, `cover_task` and `reply` from extract; Ask's four documented fields; all 17 draft pairs; and transcription text. No legal source file is read by the client.
6. Work in separate Cover/Write, Ask/Report and server files as assigned in `AGENTS.md`. Only the cover is currently mounted; actual navigation and access remain feature work.
7. Read the report target through `ReportTarget.current`. The later form owner must use this guard; no submission code exists yet.

## Base acceptance complete

Xcode 27.2 setup passed. Debug and Release builds and all 13 tests in each configuration passed. The Debug app was reinstalled and launched on the iPhone 17 Pro / iOS 26.5 simulator, and its empty cover was visually verified. The working copy is ready for the owner's review and handoff to parallel builders. Physical-device signing and real feature behaviour are outside this base verification. Key management remains OPEN before the later encrypted-storage phase. No other phase was started.

No commits, staging, branches, pushes, merges or git-history changes were performed.
