# Integration review and fixture results

7 November 2026. Reviewed `AGENTS.md`, `BUILD_PLAN.md`, the brief, product changes,
architecture, AI contracts, fixtures, and the three implementation logs.

## Repository and integration

The requested implementation was already on `main` at the start of this review:

| Owner | Committed work | Status |
|---|---|---|
| A — server | `cc261d2` includes `server/` and its tests/log | Present on main; local implementation verified. Deployment and human checks remain. |
| B — cover, Write, storage, voice, HTTP connection | `8ef1e85`, included by merge `e432589` | Present on main; simulator implementation verified. Physical-device checks remain. |
| C — Ask and Report | `cc261d2`, alongside A's files | Present on main; mock flow implemented. Real-form mapping was deferred with owner approval. |

The working tree was clean when this review began. The named `server-ai`,
`cover-write`, and `ask-report` branches do not exist in this checkout. A and C
were committed together before B. No merges were performed or reordered, and no
build-after-each-merge result is claimed. Git history was not changed.

The production entry point already constructs `HTTPServerClient.configured()`
and `EncryptedEiraStore`. One unlocked `PrivateSessionStore` is passed to Write,
Ask and Report through the workspace dependencies. Canned responses and the
in-memory store remain available for tests and previews.

The live integration test now runs the actual Write, Ask and Report flows using
the same encrypted store and HTTP client. It checks a report description sourced
from Write, a saved Ask question, an edited field surviving lock/unlock, and
transcription followed by temporary audio deletion.

The owner then approved two focused changes: reuse entry-use controls under Ask
questions, and replace passphrase setup/normal unlock with direct `eira` access
and device-held encryption (PRODUCT C13). The control offers legal-guidance and
report switches for questions. Restricted questions remain visible for later
permission changes; excluded text and dependent answers stay out of subsequent
AI context, and retry does not send a restricted question.

A new random key lives in the phone's non-syncing Keychain. It is requested with
[Apple's this-device-only, unlocked-device accessibility](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly).
The in-memory key and records are dropped on lock. The exact trigger opens the
private area without asking her to create or enter a password. Existing
passphrase-protected records require one correct unlock for conversion; wrong
phrases leave their bytes unchanged. Missing device keys or malformed records
fail without replacing data. Deletion removes the Keychain item and private
file, while cover tasks remain. No prompt wording or report-delivery behavior
was changed.

## Verification performed

| Check | Result |
|---|---|
| Server deterministic tests: `cd server && npm test` | PASS — 18 tests, no failures or skips. |
| Server live fixtures: `cd server && npm run test:live` | PASS — 14 automated groups; 15 passes including the parent test, one human-only VO7 skip. |
| Server package: `cd server && npm run build` | PASS — explicit allowlist, zero approved FAQ answers, no excluded legal files in the output. |
| Signed Debug simulator suite, live integration and existing invented synthetic audio enabled | PASS — 49 tests, no failures or skips. |
| Signed Release simulator suite, report target explicitly overridden to mock, live calls disabled | PASS — 48 passed, one opt-in live test skipped, no failures. |
| Simulator test screenshots | Inspected Ask caveat, draft review, confirmation, mock form, receipt and large-text sources. |

The first C13 simulator run used the old unsigned command and failed Keychain
access with status -34018. An isolated check confirmed the missing signing
permission. Ad-hoc simulator signing then passed all 27 focused tests and the
full 49-test Debug suite. `AGENTS.md` now uses `CODE_SIGN_IDENTITY=-` for simulator
commands. No entitlement bypass or unencrypted fallback was added.

All calls used invented samples. Legal tests used the test runner's invented FAQ;
the production approved file was not edited. No real SAPA page was loaded or
filled. The mock was the only form exercised. The Release override was
`EIRA_RELEASE_REPORT_TARGET=mock`; Debug also enforces mock in code.

Final simulator result bundles:

- Debug: `.build/ReviewSignedData/Logs/Test/Test-Eira-2026.11.07_13-04-19-+0700.xcresult`
- Release: `.build/ReviewSignedData/Logs/Test/Test-Eira-2026.11.07_13-05-25-+0700.xcresult`
- Inspected screenshots: `.build/ReviewAttachments/` and updated Ask controls in `.build/ReviewSignedAttachments/`.

Reproduce from the repository root, with the local server running and the
ignored simulator configuration already present:

```sh
TEST_RUNNER_EIRA_LIVE_TESTS=1 \
TEST_RUNNER_EIRA_LIVE_AUDIO="$PWD/.build/InventedVoice.m4a" \
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug \
  -destination 'platform=iOS Simulator,id=CDEBB40E-648A-457A-8B41-C58E0DDE7100' \
  -derivedDataPath .build/ReviewSignedData -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test

xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Release \
  -destination 'platform=iOS Simulator,id=CDEBB40E-648A-457A-8B41-C58E0DDE7100' \
  -derivedDataPath .build/ReviewSignedData -parallel-testing-enabled NO \
  EIRA_RELEASE_REPORT_TARGET=mock CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
```

The audio path points to an existing invented synthetic fixture, not a recorded
person. Live checks consume API credits. The test copies the clip to its own
temporary directory and verifies that transcription deletes that copy.

## Fixture table

PASS means the stated check has supporting evidence. FAIL identifies an observed
gap. NOT RUN means a required part could not be completed; passing automated
parts are described explicitly and do not turn that row into a full pass.

| ID | Result | Evidence or remaining work |
|---|---|---|
| E1 | PASS | Live M1: three events, relative time, cheek swelling/head impact, Dimas and valid quotes. Live iOS integration also returned three validated events. |
| TG | PASS | Live 5 × 3 grid below meets the fixture's Pass scoring. |
| Q1 | PASS | Five live drafts plus deterministic invented-pair rejection and checks across all 17 fields. |
| Q2 | PASS | Swift and server checks reject corrupted quotes. |
| Q3 | PASS | Capitalization and harmless punctuation changes accepted. |
| Q4 | PASS | Concern stayed empty in all five live M1 drafts. |
| Q5 | PASS | Live extraction/drafts and deterministic checks found no invented husband name. |
| Q6 | PASS | Empty and punctuation-only quotes rejected. |
| L1 | PASS | Live X4 against invented approved FAQ passed the verdict wording check. |
| L2 | PASS | Live X3 against invented answer 4 kept the range general, named the judge's role and included the caveat. |
| R1 | PASS | Live M1/X1 wording checks; stored reply remains separate from entry text and is never a quote source. Write renders it below her message. |
| P1 | PASS | Live generated tasks passed validation; reserved trigger, private text and source overlap rejected deterministically. |
| U1 | PASS | Shared permission controls now appear under Ask questions. A new encrypted-store regression test restricts a question from Report, clears its sourced draft field and verifies that subsequent draft requests exclude it; restrictions persist after reopening. Existing story filtering checks still pass. |
| U2 | PASS | Restricted questions remain visible to restore permissions, but do not enter allowed context, conversation or retries. Dependent replies are removed. Encrypted-store restriction/reopen/restore tests and existing filtering checks pass. |
| S1 | PASS | Bundled WebKit mock receipt stays empty until the test simulates her press on its own send button. No application submit/click path. |
| S2 | NOT RUN | Debug forced-mock behavior and Release-with-mock pass. There is no demo branch to build; its required setting has not been verified. |
| S3 | PASS | All 17 mock controls/receipt values match the draft, including edits, nulls, booleans, dropdowns and executable-looking text treated as data. |
| N1 | NOT RUN | Copy/source review, UI captures and live wording checks passed their automated scope. A complete human reading of every screen and generated answer remains. |
| A1 | PASS | Temporary-file deletion passes forced success/failure tests. Live synthetic Indonesian transcription through VoiceFlow also deletes the temporary copy. Physical microphone interaction remains unverified. |
| B1 | NOT RUN | C13 state tests pass inactive hiding, background lock, cleared records/caches and required later exact trigger. Actual app-switcher snapshot/lifecycle timing on the phone remains unverified. |
| V1 | PASS | Server and app checks for 4/7/11; inspected visible Ask caveat screenshot. |
| CF1 | PASS | Confirmation gates form opening and changes to sources invalidate confirmation; inspected confirmation capture. |
| CV1 | PASS | Encrypted Write save creates a separate unrelated task; locked cover CRUD works without reading private records. |
| DL1 | PASS | Secret envelope and actual Keychain item removed, cover tasks preserved, next exact trigger opens an empty private area with a new key, and old session is rejected. |
| DS1 | PASS | Exact lowercase trigger consumed and opens the private area directly; case/space variants remain ordinary tasks. No password creation or normal unlock screen. One-time conversion preserves existing entries/draft/tasks and rejects wrong phrases without altering their file. |
| VO1 | PASS | Live reply set contains no tested banned stock lines. |
| VO2 | PASS | No formal Anda in the live reply set. |
| VO3 | PASS | Consecutive openings differ in the tested extract and Ask sequences. |
| VO4 | PASS | Live replies have at most one question and no detected lists/headings. |
| VO5 | PASS | X3/X4 answers use a relevant M1 detail against invented test FAQ. |
| VO6 | PASS | No claimed app feelings/personal experience in the tested replies. |
| FA1 | PASS | Live unsupported topic hands off despite a related approved test slot; deterministic checks reject unsupported FAQ IDs. |
| FA2 | NOT RUN | Local package allowlist and runtime-reference checks pass. No deployment exists to inspect. Prohibited legal files were not read for comparison text. |
| FA3 | PASS | Empty production FAQ hands off; deterministic test confirms no model call. |
| VO7 | NOT RUN | Requires two Indonesian teammates to read actual replies aloud. Explicitly skipped by the live runner. |
| Refusal handling | PASS | Deterministic refusal retry, fallback, incomplete-output and safe-error checks pass. No failure diagnostic occurred in the final live fixture run. |

| T3 sample | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| 1 | fisik | fisik | fisik |
| 2 | psikis | psikis | psikis |
| 3 | seksual | seksual | seksual |
| 4 | penelantaran | penelantaran | penelantaran |
| 5 | psikis | psikis | psikis |

Sample 5's psikis is allowed by the fixture; tidak_yakin is preferred.

## Remaining limits and owner changes

- The real form connection remains intentionally deferred. Release's real
  target fails closed to the copy fallback; it is not a working real-form path.
- The phone was subsequently confirmed to have `org.eira.app` installed. Its
  Debug plist has neither the server address nor the app token; the ignored
  settings currently apply only to simulators. This explains saved entries
  without AI replies on the physical phone. The local server returned 405 to a
  read-only GET check, confirming its listener is running.
- The owner approved preparing a temporary HTTPS connection. The official
  Cloudflare tunnel tool (2026.10.7) was downloaded to `.build/Tools/` and checked
  against its published SHA-256 digest. Starting the public tunnel was rejected
  by automatic approval review because consent did not yet specifically cover
  app text/audio passing through Cloudflare. Explicit approval was requested;
  the owner subsequently chose a local-only simulator demo. No tunnel was
  started, no phone endpoint was added, and no app payload passed to Cloudflare.
- Physical privacy checks, microphone interaction and the actual app-switcher
  snapshot remain unverified.
- The owner changed the signing team in `Eira.xcodeproj/project.pbxproj` while
  this review was running. That change was not made or reverted by this agent.
- This review's app, test, requirement-documentation changes and this log are uncommitted. No commit, push,
  branch creation, merge, or history change was performed.

The final inactive-trigger guard also passed its focused B1 regression check:
a queued `eira` task cannot reopen private records while the app is inactive.

The updated signed Debug app was installed and launched successfully on the
booted iPhone 17 Pro simulator (`CDEBB40E-648A-457A-8B41-C58E0DDE7100`). Its
compiled address is `http://127.0.0.1:3000`, its app token is present, and its
report target is mock. The server listener was checked before launch. Device Hub
UI automation timed out, so no new visual app-switcher or full-demo pass is
claimed from that attempt.

The integrated local simulator path works. Full fixture sign-off is not complete.

## C14 — English voice input

The owner approved Indonesian and English voice transcription without a selector.
The server now sends `languages: ["id", "en"]` to `gpt-transcribe`, following the
[official file-transcription guide](https://developers.openai.com/api/docs/guides/speech-to-text).
The optional `language=id` field sent by existing app builds remains accepted for
compatibility; it does not override the server's bilingual hints. No iOS code,
UI language, AI reply prompt, model or dependency was changed for C14.

- `cd server && npm test`: 18 passed, no skips or failures. The audio contract
  checks both language hints and verifies that no singular `language` parameter
  reaches OpenAI.
- Live local HTTP transcription: invented English and Indonesian synthetic M4A
  clips both passed key-detail checks and stayed in the original language. The
  English sample mentioned a husband slapping her left cheek twice, swelling,
  and a son seeing it from the doorway. The Indonesian sample used T3 sample 1.
- Initial generated WAV test clips returned 502. Regenerating valid audio with
  full audio-tool access in the app's M4A format resolved the fixture attempt;
  no application validation or expected-content check was weakened.
- All clips generated for these checks were deleted after the calls. No real
  person's voice was recorded. Microphone interaction and mixed-language
  accuracy remain unverified by these synthetic checks.
- The existing loopback server process was restarted from `server/` so the
  simulator uses the changed language hints immediately. No app rebuild is
  needed for C14. No real SAPA target or public tunnel was used.

C14 changes are uncommitted, along with the preceding integration work. Other
concurrent app/design changes were left untouched.
