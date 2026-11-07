# Eira: build plan

Event: Sea x OpenAI Regional Codex Hackathon, Jakarta, Sat 7 Nov 2026. One day, in person. No code is prewritten. The proposal requires all code to be written on the day. No clock times are set here.

## Tonight checklist (before the event)

| Item | Detail | Status |
|---|---|---|
| Fresh repo | Copy only the contents of `eira-handoff/` into the new repo. Do not copy `reports/` or `research_notes/`. Do not reuse old git history. Name the GitHub repo, the Vercel project and the OpenAI project with no banned words (see the Names row). | OPEN |
| Rehearsal tests T1 to T7 | T1 key works. T2 structured output. T3 legal tagging. T4 quote check. T5 voice keep or drop. T6 privacy settings. T7 latency and cost. The full tests live in the team's private test plan, which stays out of this repo. Results are not recorded in our notes yet. Use invented messages only. | UNVERIFIED until run |
| Lawyer review | Ideally LBH APIK Jakarta reviews FAQ answers 4, 7 and 11. Also confirm answer 12 and the reword of answer 3 (`LEGAL_FAQ.md`). | OPEN |
| Approve confirmation copy | The team approves the corrected reporting confirmation copy in `SAFETY.md`. It is DRAFT, based on AI research, not lawyer-reviewed. | OPEN |
| FAQ text | Not a blocker for the build. `FAQ_APPROVED.md` stays as it is for now, and Ask hands off until the team fills it. The team chooses the text after the app is built and tested (see "Before the demo"). | After the build |
| iOS checks | The list in `ARCHITECTURE.md` section 7. Run what can be run on a real iPhone. | UNVERIFIED |
| Store check | The brief called for a 10-minute Play Store check to confirm no Indonesian tool does this. Keep it, because most of the Indonesian market is on Android, and check the App Store too. | OPEN |
| OpenAI project key | The team gets OpenAI credits. Create the team's own project key and keep it in a password manager with an expiry date. Confirm the credits show on the account. Keep a spend alert (suggested $5) and a hard limit (suggested $10). | OPEN |
| Run T1 on venue Wi-Fi | Catches network blocks. | OPEN |
| Ask the organisers | Can we get Modified Abuse Monitoring on our project? | OPEN |
| Xcode and signing | Xcode installed, signing set up, a test iPhone or simulator ready on the build Mac. | DONE |
| Names | Name the OpenAI project, the GitHub repo and the Vercel project without the Indonesian word for "report", KDRT or SAPA. The dashboard name is low risk, so keep it simple. The Xcode project name, bundle id, display name, and the server project name and address must not contain those words either. | OPEN |
| Model names | The models are DECIDED: `gpt-6-luna` primary, `gpt-6.1-terra` for drafting and as fallback, `gpt-transcribe` for voice, reasoning `none` to start. Check the names on the dashboard. | UNVERIFIED |
| Notes available at the venue | T3 scoring grid and T4 notes in a place you can read at the venue. | OPEN |

## Ordered slices (from the brief's 7 Nov list)

The slices are built in the phases below. Slice 7 is built only if time allows after phase 3. Owners are people (A, B, C); names are filled in on the day.

| # | Slice | Delivers | Read | Fixtures that must pass | Owner |
|---|---|---|---|---|---|
| 1 | Server and one working call | A thin server with the extract endpoint, the key held on the server, `store: false`, the app token, a safe failure on refusal, and the model fallback. A way to call it from the app. | `ARCHITECTURE.md`, `AI_CONTRACTS.md` | E1 (call works, matches schema), refusal handling | A |
| 2 | Entry | The to-do-list cover and the fixed `eira` add-task access flow (DECIDED C11; no secret-name setup), the encrypted store protected by her private passphrase (C12), lock on background, hide on inactive, delete everything. | `PRODUCT.md` (disguise and secret entry, cover), `ARCHITECTURE.md`, `SAFETY.md` | B1, DL1, DS1 | B |
| 3 | Stage 1: writing chat | Typed entries, the extract call, the timeline with quotes, the quote check, the editable violence type, unrelated cover tasks in the to-do list, allowed uses stored per entry, and the AI's reply in the chat (default rules in `AI_CONTRACTS.md` call 1; how replies work is open decision 5). | `PRODUCT.md` (Stage 1), `AI_CONTRACTS.md` (call 1, quote check) | E1, TG, Q1, Q5, P1, R1, N1, CV1 | B |
| 4 | Stage 2: ask | The Ask chat grounded in the FAQ and allowed entries, non-judging rules, the plain-code caveat for answers 4, 7, 11, hand-off to a human service when appropriate. | `PRODUCT.md` (Stage 2), `AI_CONTRACTS.md` (call 2), `FAQ_APPROVED.md`, `SAFETY.md` | L1, L2, U2, V1, N1, FA1, FA2, FA3 | A (server side) and C (app side) |
| 5 | Stage 3: report | The draft call, quote check per field, the review screen with states (empty, from her words, edited by her), correction by her, the confirmation, the web view that fills the SAPA form fields from her draft, the mock form bundled in the app, and the real/mock target setting (Debug always mock). The per-field copy fallback. She presses send; the app never does. | `PRODUCT.md` (Stage 3), `AI_CONTRACTS.md` (call 3), `SAPA_FORM.md`, `SAFETY.md` (confirmation) | Q1 to Q6, U1, S1, S2, S3, CF1, N1 | A (server side) and C (app side) |
| 6 | Voice | Record, transcribe, put the text into the input, delete the audio. | `AI_CONTRACTS.md` (call 4) | A1 | B |
| 7 | Onboarding | Only if the team confirms and time allows. Mention at minimum (C6). | `PRODUCT.md` (C6) | None | Any, if time remains |

## Phases and people

Three people work in parallel after a shared base. Names are filled in on the day. The prompts for each phase are in `CODEX_PROMPTS.md`.

| Phase | What | Who | Branch |
|---|---|---|---|
| 0 | Base: project, layer folders, data models, store interface, canned server client, quote check, target setting, placeholder screens, build and test commands | Person A | main |
| 1 | Server and AI: slice 1, and the server side of slices 4 and 5 | Person A | server-ai |
| 1 | Cover and writing: slices 2, 3 and 6 | Person B | cover-write |
| 1 | Ask and report: the app side of slices 4 and 5 | Person C | ask-report |
| 2 | Merge in the order server-ai, cover-write, ask-report, then swap the canned responses and in-memory store for the real ones | Person A | main |
| 3 | Demo branch and the full demo script | Any person | demo |
| 3 | FAQ text: the team pastes its chosen text into `FAQ_APPROVED.md` before the demo | Team | none, a data file |

Slice 7 (onboarding) is built only if time remains after phase 3.

## Server setup by a person (before phase 1)

Owner: Person A. A person does these steps, not Codex.

1. Create a Vercel account and a project whose name does not contain the Indonesian word for "report", KDRT or SAPA, because the name sets the default address. Set the project's root to `server/`.
2. Add these environment variables in the Vercel dashboard: `OPENAI_API_KEY`, `OPENAI_TEXT_MODEL`, `OPENAI_FALLBACK_MODEL`, `OPENAI_TRANSCRIBE_MODEL` and the app token. Redeploy after changes.
3. A person types the key in. Never paste it into Codex, a prompt, a doc or a file that gets committed.
4. The app reads the server address and the app token from one config file.
5. UNVERIFIED, check on the day: the Vercel request body size limit against voice clips; the function time limit against report drafting; what Vercel logs by default.

## Changing a decision

Any decision can change during the day without breaking the plan. Follow these steps.

1. A person updates the decision's row in `PRODUCT.md`, with the time and the reason. Nobody edits behaviour without a row. A new feature needs a row in the changes table first (rule zero in `AGENTS.md`).
2. Find the decision in the swap points table below: where it lives, who owns it, and which fixtures to rerun.
3. Paste the change prompt from `CODEX_PROMPTS.md` into the owner's Codex account. Only that owner changes it.
4. Rerun the listed fixtures. Log the change in that owner's codex log.
5. Timing. During phase 1, the owner makes the change on their own branch. During a merge (phase 2), wait until the merge finishes. After phase 3, change it on `main`, then recreate or update the demo branch so that its only difference stays the report target. If a change touches the shared data models, only Person B makes it.

**Swap points**

| Decision | Where it lives | Owner | Rerun |
|---|---|---|---|
| Disguise | The secret entry files and the cover files | Person B | B1, CV1, DL1, DS1 |
| Per-story control | One setting and one component; the data model does not change | Person B | U1, U2 |
| Stage 1 reply | The server prompt and the reply field in the chat | Persons A and B | R1, VO1 to VO7 |
| AI wording and voice | Server prompt files only, no logic | Person A | L1, L2, R1, VO1 to VO7 |
| FAQ text | `FAQ_APPROVED.md`, no code | Team | FA1 to FA3, V1 |
| Models | Environment variables, no code | Person A | E1 |
| Report delivery and target | The target setting and the web view | Person C | S1, S2, S3 |
| Confirmation and privacy copy | One strings file. `SAFETY.md` is the source of the text | Person C | CF1 |

## Rules while working in parallel

- Each account stays in its own files: Person A in `server/`, Person B in the cover, Write, store and voice code, Person C in the Ask and Report screens and the form web view.
- After the base, only Person B changes the shared data models. Anyone else who needs a change asks a person, who brings it to Person B.
- Canned server responses and the in-memory store stand in until the merge.
- Each agent works on its own branch in its own folder. On one Mac, each agent uses its own simulator.
- Only people merge. Codex agents never merge.
- The to-do disguise and fixed `eira` access task are DECIDED (C11); per-story control (open decision 1) remains PROVISIONAL in `PRODUCT.md`. C12 decides passphrase setup and unlock, with no automatic unlock or recovery. Language (open decision 3) is DECIDED: Indonesian. To change any decision, follow "Changing a decision" below.

## Before the demo

Phase 3 covers this. After the merge works, the demo branch is created from `main`. It forces the mock target for all builds and changes nothing else. The full demo script in `FIXTURES.md` is run on it, and S2 is checked there. The demo runs only from that branch.

FAQ text: `FAQ_APPROVED.md` stays as it is until the app is built and tested. Then the team decides which text to use and pastes it in. The team can swap it any time, because it is a data file and needs no code change. The server still loads only that file. Until text is pasted, Ask hands off. The team may paste candidate text during testing to compare versions, but test only with invented messages. Demo step 5 needs answer 1 filled in by then (see `FIXTURES.md`).

## Cut list, in order

1. Onboarding. It is not built by default. The demo mentions it aloud.
2. Voice.
3. Real-form fill, falling back to per-field copy (the mock demo is kept if possible).

Never cut:

- The quote check.
- Never auto-send.
- The confirmation before sending.
- The encrypted store.
- The fixed `eira` add-task access flow; there is no secret-name setup (C11).
- The non-judging rules.

## How Codex is used (PROPOSED for team confirmation)

The brief lists this as an open question and a judged criterion. Proposal:

1. Three Codex accounts work in parallel after a shared base. Person A builds the base on `main`, then A, B and C each take a branch (see "Phases and people"). The prompts to paste are in `CODEX_PROMPTS.md`.
2. Give each Codex `AGENTS.md` and the docs named in its prompt. Do not give it anything not in the docs.
3. The team reviews each phase against its fixtures before the next phase starts.
4. Keep one log file per phase: what Codex was asked, what it produced, and which fixtures passed or failed. The judges can read them.
5. Run Codex locally on a Mac so it can use Xcode tooling. Check that this works at the event before relying on it, including more than one simulator at a time.
6. If Codex suggests a feature that is not in the docs, it stops and asks the team (`AGENTS.md`, rule zero).

## Fill in on the day

Which FAQ answers are filled in `FAQ_APPROVED.md`, and who approved each (the build works with any number, including none). Who is Person A, B and C. The app token variable name. Commands in `AGENTS.md`, written by the base. The answers to the other open decisions in `PRODUCT.md`. Indonesian teammates write the 3 to 5 prompt examples and run the read-aloud review.
