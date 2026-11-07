# Eira: instructions for the coding agent

You are building Eira, a native iOS app, at a one-day hackathon on Sat 7 Nov 2026. No code is prewritten. The hackathon proposal requires all code to be written on the day. Start from an empty project.

## Working with the owner

- Never commit, push, merge, create a branch, or change git history. The owner handles git operations.
- For new files, dependencies, changes across three or more files, or work requiring close review: explain the plan in plain language and wait for approval. A precisely described small change may proceed. The owner approved this shared-base plan on 7 Nov 2026.
- Lead with visible behaviour and plain language. No generic AI copy or marketing language.
- Current phase: shared base only. Empty screens, in-memory storage and canned server responses are deliberate. Do not start feature work without a new request.
- C11 supersedes the original disguise: a to-do cover, opened by adding a task named exactly `eira`, with unrelated generated cover tasks. No plant-name setup. The base does not implement that access flow.
- The fixed trigger is not an encryption secret. Key management is OPEN; a person must resolve it before the encrypted-storage phase.

## Rule zero

Follow `docs/BRIEF.md` and the "Changes since the brief" table in `docs/PRODUCT.md` exactly. Never create, add, or suggest building any feature, screen, setting, or behaviour that is not in those two documents. If something seems missing, or you think of a better idea: stop and ask the team. Do not build it. "Nice to have" is not permission. The other files in `docs/` explain how to build what those two documents ask for; they do not add scope. Where documents conflict, the brief plus the changes table wins.

## Non-negotiable rules

1. Never auto-send. The app never presses send on anything. She sends the report herself.
2. No source, no field. Plain code (not the AI) rejects any field whose quote is not in her text.
3. No server database and no server copy of her records.
4. Audio is transcribed, then discarded. Delete the file whether or not the call worked.
5. `store: false` on every text call to OpenAI.
6. The OpenAI key lives only on the server. Never in the app.
7. The Indonesian word for "report", KDRT and SAPA are never visible outside the secret area: not in the app name, icon, notifications, cover screens, or the server domain.
8. No push notifications. No notification permission request.
9. Never claim Eira keeps her safe. Claim only that it helps her understand her options.
10. Legal answers are information, never a verdict. Never say someone is proven to have committed a crime. Never apply a sentence to her husband.
11. Entries she has limited from a use are excluded from that use, including from anything sent to the AI.
12. The real SAPA submission code lives on `main`, but never run the real target with test data. Debug builds use the mock. The demo runs from the demo branch, which forces mock. Never submit test data to the real form.
13. Use invented text only (see `docs/FIXTURES.md`). Never use a real person's words.
14. The server loads legal answers only from `docs/FAQ_APPROVED.md`. Never load, read for answer content, copy from, or bundle `docs/LEGAL_FAQ.md` or `docs/LEGAL_REVIEW_LOG.md`. Never fill in or edit an answer slot in `FAQ_APPROVED.md`; only the team does that. A slot with no approved text does not exist for the AI. If her question falls on such a slot, Eira says plainly that it cannot answer that yet and hands off to a human service. It does not improvise law. Never call the FAQ lawyer-checked.
15. Name things in English in code. For the report feature use Report, never the Indonesian word for report. This covers identifiers, file names, folders, comments, commit messages, branch names, logs, the bundle id and the server domain. The only allowed exceptions are the real SAPA form address and ordinary Indonesian text in copy or test samples. Do not describe any earlier version of this project or any earlier platform plan anywhere.

## Doc map

| If you are working on | Read |
|---|---|
| Anything (start here) | `docs/BRIEF.md`, then `docs/PRODUCT.md` |
| What a screen or stage must do, acceptance criteria, open decisions | `docs/PRODUCT.md` |
| App structure, storage, server, data model, what leaves the phone | `docs/ARCHITECTURE.md` |
| Any OpenAI call, schemas, quote check, legal article map | `docs/AI_CONTRACTS.md` |
| Report fields and dropdown values | `docs/SAPA_FORM.md` |
| Grounding text for "what happens to me?" answers (the only FAQ text the server loads) | `docs/FAQ_APPROVED.md` |
| Team review of the legal answers. Never grounding text, never loaded by the app, not for builders | `docs/LEGAL_FAQ.md`, `docs/LEGAL_REVIEW_LOG.md` |
| Cover, privacy text, confirmation text, banned claims | `docs/SAFETY.md` |
| Test samples, must-pass and must-fail table, demo script | `docs/FIXTURES.md` |
| Order of work, cut list, how Codex is used | `docs/BUILD_PLAN.md` |

Design is not specified. It is changing. There is no DESIGN.md. Do not invent a visual style beyond what is needed to make the screens work. Ask the team.

## Status labels used in the docs

DECIDED means build it. OPEN means the team has not decided: do not build it, ask. UNVERIFIED means a fact or check nobody has confirmed. PROPOSED means suggested and the team may strike it. DRAFT means copy that will be refined on the day. PROVISIONAL means build it now, it may change later, so keep it swappable.

Rule for PROVISIONAL choices: Keep each PROVISIONAL choice in its own file or setting, so nothing else depends on its details. Do this with plain separation; add no abstractions beyond what this needs. If a decision changes, follow "Changing a decision" in `docs/BUILD_PLAN.md`.

## Build and test commands

Run from the repository root with Xcode 27.2 selected. Minimum deployment target: iOS 17.0. No third-party packages are needed. `Eira/` and `EiraTests/` are Xcode folder-synced groups: add source files on disk without editing `project.pbxproj`. `docs/`, `server/` and configuration files are outside the app resource group.

Choose an available simulator (each parallel agent uses its own device):

```sh
xcrun simctl list devices available
export EIRA_SIMULATOR_ID=CDEBB40E-648A-457A-8B41-C58E0DDE7100
```

Build Debug:

```sh
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug \
  -destination "platform=iOS Simulator,id=$EIRA_SIMULATOR_ID" \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Run on the simulator. Skip `boot` if that device is already booted:

```sh
xcrun simctl boot "$EIRA_SIMULATOR_ID"
xcrun simctl bootstatus "$EIRA_SIMULATOR_ID" -b
xcrun simctl install "$EIRA_SIMULATOR_ID" .build/DerivedData/Build/Products/Debug-iphonesimulator/Eira.app
xcrun simctl launch "$EIRA_SIMULATOR_ID" org.eira.app
```

Run tests (boot the simulator first):

```sh
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug \
  -destination "platform=iOS Simulator,id=$EIRA_SIMULATOR_ID" \
  -derivedDataPath .build/DerivedData -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test
```

Verify Release configuration on the simulator without reaching a real service:

```sh
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Release \
  -destination "platform=iOS Simulator,id=$EIRA_SIMULATOR_ID" \
  -derivedDataPath .build/DerivedData -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test
```

Report delivery is controlled by `Configuration/ReportTarget.xcconfig`: Release defaults to `real`. `Configuration/Info.plist` expands the selected value into the app metadata read by `ReportTarget.current`. Debug uses `mock` and `ReportTarget.current` enforces mock even if a build-setting override says real. The later demo branch changes only `EIRA_RELEASE_REPORT_TARGET` to `mock`. No web view, endpoint URL or submission code exists in this base.

Run on a physical iPhone (not verified in the base; a person supplies their own device ID and signing team):

```sh
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug \
  -destination "platform=iOS,id=$EIRA_DEVICE_ID" -derivedDataPath .build/Device \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$EIRA_TEAM_ID" build
xcrun devicectl device install app --device "$EIRA_DEVICE_ID" .build/Device/Build/Products/Debug-iphoneos/Eira.app
xcrun devicectl device process launch --device "$EIRA_DEVICE_ID" org.eira.app
```

Server commands: none yet. `server/` is intentionally empty; the server agent supplies its build, run and test commands in phase 1. Git does not retain empty directories, so use `mkdir -p server` in a fresh checkout if needed.

## Shared base contracts and ownership

- `Eira/CoreRules/Models.swift`: `Entry`, `AllowedUses`, `EntryKind`, `Event`, `ReportDraft`, `ReportDraftField`, `ReportValue` and `CoverTask`. Only Person B changes shared models after this base.
- `Entry` keeps exact text and phone time immutable. `kind` distinguishes stories from her Ask questions. Events reference their entry and inherit its allowed uses; they do not copy the flags.
- `CoverTask` has local ID, title, creation time and completion flag, with no private entry link or source marker. Access handling remains future work; generated titles must not be `eira`.
- `Eira/CoreRules/EntryUseDefaults.swift`: the one PROVISIONAL all-on default. The three-switch UI remains future work.
- `Eira/CoreRules/QuoteCheck.swift`: portable Foundation only; NFKC, lowercase, quote replacement, punctuation removal, whitespace collapse, non-empty substring check. Validates events, clears unsupported AI fields and sets source IDs from allowed entries. Her edits survive. It checks quote provenance only; field-type/dropdown validation belongs to the later Report slice.
- `Eira/Storage/EiraStore.swift`: main-actor, async/throwing record access. `InMemoryEiraStore` is the replaceable stand-in. Secret deletion preserves cover tasks. Nothing is persisted or encrypted.
- `Eira/ServerClient/ServerClient.swift`: async/throwing extract, ask, draft and transcribe interface and typed wire records. Swift properties use English camelCase; wire keys match `AI_CONTRACTS.md`. Ask and draft request constructors exclude disallowed entries. Ask callers must also supply an allowed conversation; assistant messages are context only, never quote sources.
- `CannedServerClient` uses invented fixtures only. Extract returns `events`, `cover_task` and `reply`; unknown input gets no fixture event. Ask hands off with no FAQ/article claims. Draft returns all 17 value/quote pairs with explicit nulls where unknown. Transcribe returns the invented fixture as text. It performs no I/O or audio deletion; the later voice owner handles file cleanup.
- `AppDependencies` is the composition point for the stand-ins. Replace implementations there during integration without changing protocols.
- Person A: `server/` and the real client implementation. Person B: cover, Write, store, voice, models and access handling. Person C: Ask, Report, report delivery and form web view. Coordinate changes to shared bootstrap/config files through a person.
- Separate screen files: `UI/Cover/CoverScreen.swift`, `UI/Write/WriteScreen.swift`, `UI/Ask/AskScreen.swift`, `UI/Report/ReportScreen.swift`. Only the cover is mounted by the app. No secret navigation or feature flow exists yet.

