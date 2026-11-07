# Server build log — 7 November 2026

## Request and approved scope

Build only the thin Node server with the `openai` package: extract, Ask, draft,
and transcription. Keep the iOS app untouched. Hold the API key, prompts, schemas
and approved FAQ on the server, keep no records/audio, and never log request or
response bodies. Follow the AI contracts and Indonesian voice direction. Leave
the team's written-example slots empty. Never read or ship the other legal
documents, and never edit an approved FAQ slot.

The owner approved the plan and a 4,000,000-byte audio cap, fitting Vercel's 4.5 MB
request limit. The owner configured a local OpenAI key; its value is not recorded
here. The separate app token was generated locally. No git history operations
were performed and no iOS file was edited. This log is the requested exception
to ownership of `server/` only.

## Built

- Four POST handlers under `server/api/`, plus a local Node runner.
- Shared-token authentication; exact request-shape checks; request size limits;
  clean Indonesian errors; no response caching or private body logging.
- Responses API calls with strict schemas, `store: false`, reasoning `none`,
  bounded output, no person identifiers and no `previous_response_id`.
- A bounded primary/fallback loop with one retry for refusal on each model,
  incomplete-output handling and metadata-only failure diagnostics.
- Extraction with events, unrelated `cover_task`, and Indonesian `reply`.
  Invalid event quotes are dropped; unsafe cover titles are rejected.
- Ask reads only filled approved FAQ slots. An empty FAQ works without a model
  call. Unsupported answers hand off. Source numbers are checked, named articles
  must occur in cited approved text, and plain code adds the caveat for 4/7/11.
- All 17 report pairs, strict dropdowns and types, quote checking, age/phone/text
  limits and empty inferred concern. Phone code still assigns source IDs and
  preserves her edits.
- In-memory multipart transcription with `languages: ["id"]`, neutral outgoing
  filename, and the approved 4 MB cap. No audio file is written by the server.
- Plain prompt files with empty team-example slots. Hand-off/caveat build-default
  text is separately editable. The server retains no conversation; only a small
  generic hand-off variant index is retained to vary consecutive openings.
- An explicit deployment allowlist in `server/scripts/build.js`. Only filled
  approved FAQ text is copied into the package. No secrets, tests, iOS files,
  unfilled FAQ questions, or other legal documents are copied.
- `server/README.md` documents platform setup, environment variables, local
  commands, deployment preparation, and exact request/response shapes.

## Verification

`npm test`: **18 passed**, no skipped checks. These are deterministic checks with
invented text and mocked OpenAI responses, not proof of model quality.

Local HTTP smoke: **6 passed** — POST-only handling, authentication, empty-FAQ
Ask, malformed draft, wrong audio media type, and unknown route. The real local
listener was used. Response bodies were not printed.

Live tests use only `docs/FIXTURES.md` samples. Tests needing approved text create
an invented FAQ inside the test setup. No real legal text was used for them.
Fixture assertions have not been weakened or changed after wording failures.

| Check | First full live run | Second full live run |
|---|---|---|
| E1 | Failed: head impact omitted from injuries | Passed |
| TG | Failed: sexual-coercion sample mistagged | Failed: both generated cover titles rejected; remaining grid incomplete |
| Q1, Q4, Q5 | Passed five drafts | Passed five drafts |
| P1, R1 | Automated checks passed | Automated checks passed |
| L1 | Passed automated check | Failed wording check |
| L2 | Failed sentence-applied wording check | Passed automated check |
| FA1 | Passed | Failed: related approved answer used for an unsupported topic |
| FA2 | Local package allowlist check passed | Local package allowlist check passed |
| FA3 | Passed | Passed |
| VO1, VO2, VO4, VO6 | Passed | Passed |
| VO3, VO5 | Failed | Passed |
| VO7 | Human review pending | Human review pending |

Prompt corrections after those findings: retain all physical effects and impacts;
recognise informal sexual coercion; avoid even hedged verdict/sentence phrases;
require direct coverage of the main question rather than a related legal topic;
include a relevant allowed-entry detail; vary openings; and make cover titles
short, unrelated and free of private words. Ordinary titles with a final period
are accepted by validation. A focused three-run recheck of the sexual-coercion
sample passed after these changes.

### Final live run

**14 live check groups passed, zero failures.** The test runner reports 15 passes
when it includes the parent test, plus one skipped human-only VO7 check. No
refusal or fallback diagnostic was emitted during this final run.

| Fixtures | Final result |
|---|---|
| E1 | Passed: three events, physical effects including head impact, Dimas, relative time, valid quotes |
| TG | Passed all 15 runs; grid below |
| Q1, Q4, Q5 | Passed all five draft runs: no invented name, supported quotes only, concern empty |
| P1, R1 | Automated checks passed; human reading remains part of VO7 |
| L1, L2 | Automated wording checks passed against invented approved test FAQ |
| FA1 | Passed: unsupported penalty topic handed off despite a related approved slot |
| FA2 | Local package allowlist and runtime-reference checks passed; deployed inspection not performed |
| FA3 | Passed: empty production-approved file handed off without making a model call |
| VO1, VO2, VO3, VO4, VO5, VO6 | All automated checks passed |
| VO7 | Pending two-person read-aloud review; not counted as a pass |

| T3 sample | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| 1 | fisik | fisik | fisik |
| 2 | psikis | psikis | psikis |
| 3 | seksual | seksual | seksual |
| 4 | penelantaran | penelantaran | penelantaran |
| 5 | psikis | psikis | psikis |

Sample 5's `psikis` is permitted by the fixture; `tidak_yakin` remains the ideal.
The final run meets the fixture's Pass scoring. Local deterministic tests were
rerun after the implementation/package changes: 18 passed. The current build
contains zero approved FAQ answers. The server was started locally on
`http://127.0.0.1:3000` and its six HTTP checks passed. No deployment was made.

## Remaining human and deployment checks

- VO7: two Indonesian teammates must read the actual replies aloud and mark
  anything unnatural. Rerun after every prompt change. The owner agreed to this
  process; no completed read-aloud review is claimed.
- VO1–VO6 and legal checks include automated text checks; they cannot establish
  that every possible model answer is faithful, legally grounded or natural.
- No actual audio fixture was supplied for an Indonesian/mixed-language quality
  check. Multipart handling, limits and failure handling were checked with mocks.
- iOS chat rendering, consent filtering before requests, phone audio deletion,
  real-device behaviour and integration are the other owners' work, unverified here.
- No Vercel deployment was performed. Host request/error logs, source visibility,
  rate limits and the deployed package must be checked before the demo. FA2 was
  checked locally by explicit exclusion, without reading the prohibited legal
  documents to compare distinctive sentences.
- Prompt example slots remain for the Indonesian team. No approved FAQ answer
  was filled or edited by this work; the source currently has no approved text.
