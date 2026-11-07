# Eira: product behaviour

The brief (`BRIEF.md`) plus the table below is the source of truth. This file describes behaviour only. Visual design is deliberately not specified here, because it is changing. Screens are described by what they do.

## Changes since the brief

| ID | Topic | What changed | Status |
|---|---|---|---|
| C1 | Platform | Native iOS app. The brief says only "phone app". iOS is the demo medium because the whole team uses iOS. No Android work is in scope. The app is built in layers so a later Android version is feasible (see `ARCHITECTURE.md`). The brief's Android market figures (about 77% of the Indonesian market) stand as the reason a later Android version matters. Stack: SwiftUI, no third-party iOS libraries, plus a thin server. | DECIDED |
| C2 | Her control over each story | Each entry can be limited to what it may be used for: personal timeline, legal guidance, report. A teammate proposed checkboxes. The founder likes the idea but it must not feel like filling in a form. The data model carries allowed uses per entry from day one. Stages 2 and 3 must exclude entries not allowed for them, including from what is sent to the AI. The principle is agreed. The first version is recorded in open decision 1: all uses on by default, a quiet line under each entry in the Write chat, and a small sheet with three switches. The owner also approved reusing that control under Ask questions on 7 Nov 2026: legal guidance and report switches, with no timeline switch because questions are never extracted. Restricted questions remain visible so permissions can be restored, while excluded text and dependent replies stay out of later AI context. | DECIDED (principle). PROVISIONAL (UI, default state) |
| C3 | Correcting the AI | She can correct the AI's interpretation in the report draft before sending. The brief already has review and edit. This makes it explicit. Her edit always wins and is marked as her own. | DECIDED |
| C4 | Confirmation before sending | A clear confirmation shows what information is shared and with whom. Required. Exact copy is refined on the day. Content requirements are in `SAFETY.md`. | DECIDED (required). Copy is DRAFT |
| C5 | Non-judging legal language | Eira may identify a possible form of violence and explain the relevant article as information. It must never state that someone is proven to have committed a crime, and never apply a sentence to her husband. The brief's "names what happened using the relevant article" stays, in this informational form. Prompt tone is still being tuned by the team, so `AI_CONTRACTS.md` gives rules and must-fail tests, not final prompt text. | DECIDED |
| C6 | Onboarding | Mention at minimum. Not built by default. Last in the build plan and first in the cut list. The demo script mentions it aloud. The fixed access task needs no first-launch secret-name setup (C11). | DECIDED |
| C7 | Emergency help | Out of scope. No emergency button, screen, contact feature, danger check, or special chat reply. SAPA 129 has its own direct urgent route. | DECIDED |
| C8 | What success means | Success is not whether she reports. Stages 1 and 2 alone already deliver the value. No nudges, prompts, or progress cues pushing her toward reporting. | DECIDED |
| C9 | Report delivery | The `main` branch contains the real thing. After review and confirmation, an in-app web view with non-persistent storage opens the real SAPA form (laporsapa129.kemenpppa.go.id/lapor) and the app fills the fields from her draft. She presses the form's own send button. The app never presses send. A build target setting has two values, real and mock. Debug builds always use mock, so development cannot reach SAPA. Release builds on `main` use real. The mock is a local copy of the form, bundled in the app and built from `SAPA_FORM.md`. It shows what it received and sends nothing anywhere. The team creates a demo branch later. It forces mock for all builds, and it differs from `main` in that one setting only. The hackathon demo runs only from the demo branch. Fallback if the form cannot be filled: per-field copy on the review screen. UNVERIFIED: whether the live form has a captcha, several steps, or a login; whether the page sends anything before she presses send (for example autosave). | DECIDED |
| C10 | Only approved FAQ text reaches the AI | The server loads legal grounding text only from `FAQ_APPROVED.md`. It never loads `LEGAL_FAQ.md` or `LEGAL_REVIEW_LOG.md`, and neither is bundled with the server. `FAQ_APPROVED.md` starts with no answers approved, and the team fills it answer by answer, only with answers a person has read and is confident in. No lawyer has reviewed any answer, so it is never called lawyer-checked. A slot with no approved text does not exist for the AI: if her question falls on it, the AI says plainly it cannot answer that yet and hands off to a human service, and does not improvise law. If nothing is approved, Ask still runs and hands off. | DECIDED |
| C11 | To-do disguise and access | Updated by the founder on 7 Nov 2026, 10:03 WIB. Replace the plant disguise with a working to-do list called Eira. Adding a new task named exactly `eira` opens the actual app; any other title adds an ordinary task. Remove the user-chosen plant-name setup. Each diary entry produces one unrelated, ordinary cover task (`cover_task`), with no diary content or entry link. The fixed trigger is not an encryption secret; device-held key management is decided in C13. Reason: founder changed the disguise and access flow. | DECIDED; key management updated by C13 |
| C12 | Passphrase access and storage | Owner-approved on 7 Nov 2026; replaced by C13 at the owner's request. | SUPERSEDED by C13 |
| C13 | Direct access and device-held encryption | Owner-approved on 7 Nov 2026, 12:57 WIB. Adding exactly `eira` opens the private area directly, without passphrase setup or unlock. Keep records encrypted with a random key in this phone's Keychain, available only while the phone is unlocked, with no syncing or migration to another device. Anyone who can use the unlocked phone and knows `eira` can open the records. Existing passphrase-protected records require a one-time unlock to convert without erasing them. Hide private content when inactive; background locking drops decrypted records and in-memory keys and returns to the cover. Delete everything removes private records and their device-held key, preserves cover tasks, and the next `eira` access opens an empty private area. The trigger and server API key are never encryption keys. Reason: owner removed the extra access step. | DECIDED |
| C14 | English voice transcription | Owner-approved on 7 Nov 2026, 13:24 WIB. Voice accepts Indonesian and English, without a language switch. The server supplies both expected input languages; the transcript stays in the spoken language and enters the editable composer for review. UI and AI replies remain Indonesian. Audio deletion and all existing privacy rules still apply. Reason: owner requested English voice input for testing. | DECIDED |
| C15 | Notes cover and PIN UI | Owner-approved on 7 Nov 2026: the Notes design replaces the task-list presentation. Notes support search, pinning, text and checklists; old tasks remain as checklist notes. Exact `eira` note-title access remains direct. Build a standalone PIN screen for later backend connection, with no current authentication or access gate. No attachments or photos. Details below. | DECIDED |
| C16 | Notes access with fixed PIN | Owner-approved on 7 Nov 2026. Saving a note titled exactly `eira` consumes the trigger and opens the existing four-digit PIN screen. Only `1111` opens the private area; a wrong PIN stays on that screen with a retry message, and cancel returns to Notes. Backgrounding returns to Notes and requires the trigger and PIN again. This supersedes C13 direct access and C15's unconnected PIN UI. Encryption still uses the random device-held Keychain key, never the PIN. Existing passphrase-protected records require their one-time conversion after PIN verification; deletion still preserves cover notes. | DECIDED |



C15 — Notes cover (owner-approved, 7 Nov 2026): Replace the to-do cover with the supplied Notes home and editor design: searchable notes, pinning, text and checklists, with amber controls. Preserve existing cover tasks as notes with checklist items. Saving a new note or renaming one to the literal title `eira` consumes the trigger and opens the private area directly; C13 encryption and background locking remain. Build the supplied four-digit PIN screen as a separate, unconnected UI for later backend integration; it does not authenticate or gate access yet. No attachments or photos. This supersedes C11’s cover presentation, not private storage or generated-cover isolation.

## Persona

Sari is a design persona, not a real person. She is 32, lives in Bekasi, and was made to quit work. She is insulted daily, controlled over money, and has been hit several times. She is not ready to report. She wants to understand her options, not be told what to do. She may share a home with in-laws. Her husband may look through her phone. The in-laws and the phone checking are assumptions in the notes, not measured facts.

## Language

DECIDED (open decision 3). The UI and every AI reply are in Indonesian, using "kamu" for her and "aku" for the app's first person. There is no language toggle and none is to be built.

Voice input supports Indonesian and English (C14). Transcription preserves the spoken language; it does not translate her words into Indonesian.

## Disguise and secret entry

The to-do cover and fixed access task are DECIDED (C11). Keep access handling in its own file so it can be swapped.

1. The app opens as a to-do list called Eira. Nothing on screen suggests another purpose.
2. Adding a new task named exactly `eira` through the normal add-task flow opens the actual app. The trigger is consumed rather than saved as a visible task. Any other title adds an ordinary task, with no error or hint. There is no user-chosen access name or additional passphrase (C13). Matching uses the literal lowercase title `eira`; no aliases are specified.
3. Her records are encrypted on the phone (see `ARCHITECTURE.md`). The fixed word `eira` is only an access trigger, not an encryption secret. C13 uses a random key held by this phone, with no passphrase setup or unlock. Existing passphrase-protected records require a one-time unlock for conversion without deletion.
4. A "delete everything" control exists inside the secret area and is fast to reach. It removes all her data from the phone.
5. The app locks and hides its content when it goes to the background. On return it shows the cover.
6. Nothing about the real purpose is visible outside the secret area. The Indonesian word for "report", KDRT and SAPA are banned there.

Acceptance criteria:

1. First launch shows the to-do cover without a secret-name setup. No text mentions the actual app.
2. Adding a new task named exactly `eira` opens the private area directly without leaving that title in the cover list or showing a passphrase screen. A one-time unlock applies only when converting existing passphrase-protected records. Any other title creates an ordinary task (fixture DS1).
3. After backgrounding and returning, the cover shows and the real app needs the secret entry again.
4. Delete everything removes all her private records and their key material. The cover tasks stay. The fixed `eira` trigger must never recover deleted records; it opens an empty private area with a new device-held key afterwards.

## The cover: a working to-do list

The cover works as a real to-do list, so it passes inspection if someone opens it. She can add tasks, see the list, mark tasks complete or incomplete, and delete tasks. C11 replaces the plant list, watering log and care tips.

- Each real entry she writes produces one unrelated, ordinary cover task. Its title contains no people, feelings about home, abuse words, or information from the entry. Generated tasks never use the reserved access title `eira`.
- The cover tasks must show before the actual app is opened, so they live in a separate cover store with no link to any entry (see `ARCHITECTURE.md`).

Acceptance criteria:

1. The cover works as a to-do list without entering the actual app.
2. Writing a real entry adds one unrelated cover task. Its title contains nothing from the entry's real content and is not `eira`.
3. No screen in the cover contains the Indonesian word for "report", KDRT, SAPA, or anything about help.
4. The app asks for no notification permission and sends no notifications.

## Stage 1: Write

She chats in text. She can optionally speak (voice is last but one in the build order and second in the cut list). Each message becomes an entry saved encrypted on her phone. The AI extracts a dated timeline from it and replies to her in the chat. Nothing is added that she did not say. That the AI replies is DECIDED. How it replies is OPEN (open decision 5): the team is still working it out, and the build uses the default in `AI_CONTRACTS.md` call 1 until then.

Behaviour:

- One chat message is one entry. It stores her exact text, the phone's time, and whether it was typed or spoken.
- The extract call returns events (when, what happened, injuries, witnesses, her quote, a suggested violence type), an unrelated cover task, and a short reply in Indonesian that the chat shows under her message. Contract in `AI_CONTRACTS.md`.
- The timeline shows each event with her own quote. The date shown comes from the entry's phone time. "When" is shown as she wrote it.
- The violence type is an editable suggestion. If unsure, the AI says not sure.
- For voice: she records, the audio is transcribed, the text lands in the text input as her message, the audio file is deleted.
- Each entry carries allowed uses (C2). Under each entry in the chat, a quiet tappable line shows where it is used (personal timeline, legal guidance, report). Tapping opens a small sheet with three switches. She fills in nothing when she sends. All three are on by default. Turning off personal timeline hides the entry from the timeline; it stays stored and can still be deleted.
- Extraction runs on every new entry, whatever its allowed uses, because that is how the timeline is built.

Acceptance criteria:

1. A typed message is saved as an entry with her exact text and the phone time, encrypted on the phone.
2. Every event on the timeline has a quote that is an exact substring of the entry text (after the normalisation in `AI_CONTRACTS.md`). An event whose quote fails the check is not shown. (Default; the sources do not say what to do with a failing event.)
3. A detail she did not write (a husband's name, a specific calendar day) never appears.
4. The timeline date comes from the phone time of the entry, never from the AI.
5. She can change an event's violence type. The changed type is marked as hers.
6. The AI never states a type with confidence when the entry is unclear. It uses the not-sure value.
7. A spoken message is transcribed into the text input and the audio file no longer exists afterwards, including when the transcription call failed.
8. The chat shows no progress cue, count, streak, or prompt pointing toward reporting (C8).
9. Each entry's allowed uses are stored and respected in Stages 2 and 3.
10. After each message the chat shows the AI's reply, in Indonesian.
11. The reply adds no fact she did not write: no detail, name, date, or event that is not in her message.
12. AI-written text, including the reply, is never a quote source. The quote check runs only against her own text.
13. The reply gives no verdict. It never says someone committed a crime or is a perpetrator.
14. The reply does not nudge her toward reporting, leaving, or staying (C8).

## Stage 2: Ask

She asks what the law means for her ("what happens to me?"). The AI answers from the approved FAQ (`FAQ_APPROVED.md`) and from her allowed entries together, so she does not explain again. The brief calls this FAQ lawyer-checked, but that review is still pending, so no app copy may call it lawyer-checked until it is done (C10).

Behaviour:

- Answers are in Indonesian, grounded in the approved FAQ and her allowed entries.
- The server loads only `FAQ_APPROVED.md`. It never loads `LEGAL_FAQ.md` or `LEGAL_REVIEW_LOG.md`, and neither is bundled with the server.
- An answer slot with no approved text does not exist for the AI. If her question falls on one, the AI says plainly that it cannot answer that yet and hands off to a human service. It does not improvise law.
- If nothing is approved yet, Ask still runs. It hands off.
- It may name a possible form of violence and the article that describes it, as information (C5).
- It says when it is not sure, especially when an entry is unclear.
- Answers built on FAQ answers 4, 7 or 11 carry a visible caveat that a lawyer has not reviewed them.
- It points to a human service (SAPA 129, a legal aid group such as LBH APIK, the regional unit UPTD PPA) when appropriate.
- It never tells her to leave, to stay, or to report (C8).
- Entries not allowed for legal guidance are not used and not sent.

Acceptance criteria:

1. An answer to a question covered by an approved FAQ answer matches that answer and does not add legal claims beyond it.
2. A question that her entries bear on gets an answer that uses the allowed entries.
3. An entry limited from legal guidance is absent from the request sent to the AI and from the answer.
4. The answer may say an event could be a form of violence under a named article. It never says her husband committed a crime, and never gives a sentence for him.
5. An answer that relies on FAQ answer 4, 7 or 11 shows the caveat. The app adds the caveat in plain code, not only through the prompt.
6. Where unsure, the answer says so and suggests a human service.
7. No answer tells her to leave, stay, or report. No screen nudges toward reporting.
8. Answers never claim that Eira keeps her safe.
9. A question that falls on an unapproved answer gets a plain "I cannot answer that yet" and a hand-off to a human service, with none of the unapproved text.
10. With an empty `FAQ_APPROVED.md`, Ask still runs and hands off cleanly.

## Stage 3: Report

She can build a report draft for SAPA 129 when she chooses. The draft uses the SAPA fields and dropdown values (`SAPA_FORM.md`). It is filled from her allowed entries and what she said while asking.

Behaviour:

- Each field shows its value next to the quote from her words.
- A field with no source in her words stays empty. She can fill it herself.
- Her edits are marked "edited by her" and always win over the AI. A later refresh must not overwrite them.
- She can correct the AI's interpretation of any field before sending (C3).
- A draft made earlier can be refreshed when she adds entries.
- She reviews the draft on a review screen. Before anything leaves the app, a confirmation shows what is shared and with whom (C4).
- After she passes the confirmation, an in-app web view with non-persistent storage opens the SAPA form and the app fills the fields from her draft (C9). On the real target this is the live form. On the mock target it is the bundled local copy, which shows what it received.
- She presses the form's own send button. The app never presses send, and never submits by any route.
- Debug builds always use the mock. Release builds on `main` use the real form. The demo branch forces the mock.
- Fallback if the form cannot be filled: the review screen offers a copy action per field.

Acceptance criteria:

1. Every filled field has a quote that passes the quote check. A field whose quote is missing or not found is empty.
2. Dropdown fields only hold values from `SAPA_FORM.md`.
3. Fields that need interpretation (for example how worried she is) are empty unless her words support them. She can choose a value herself.
4. Each field shows one of three states: empty, from her words, edited by her.
5. If she edits a field, it shows "edited by her" and a refresh keeps her edit.
6. The confirmation shows the fields to be shared and who receives them, and she must pass it before the form opens. Copy is DRAFT.
7. The web view fills the form fields from her draft, using the current values including her edits. Test this against the mock only.
8. No code path presses the form's send button or submits the form. She presses send herself.
9. A Debug build or a build from the demo branch cannot reach the real form.
10. An entry limited from "report" does not appear in the draft and is not in the request sent to the AI.
11. The confirmation or its neighbouring screen carries no urging language (C8).
12. The required fields from `SAPA_FORM.md` are flagged when empty, so she knows what the real form will ask for. This is information, not a push.
13. If the form cannot be filled, the review screen offers per-field copy instead.

Note on the copy fallback: per-field copy puts text on the system clipboard, which is UNVERIFIED as an exposure. The team decides what to do if the fallback is used.

## Out of scope

- Emergency button, emergency screen, emergency contacts, a danger check, and any special chat reply for danger (C7).
- Push notifications, local notifications, and the notification permission request.
- Onboarding, unless the team confirms and time allows (C6).
- A duress PIN or decoy mode.
- Auto-sending, scheduled sending, or sending on her behalf by any route. The app fills the form; she presses send.
- Accounts, login, cloud backup of her records, server database.
- Photos, camera capture, saving anything to Photos or Files.
- A quick-exit button beyond locking when the app goes to the background.
- Android work in this build. A later Android version is the reason for the layered structure in `ARCHITECTURE.md`.
- Live (spoken, two-way) voice. Only record, transcribe, discard.
- Any progress cue, streak, reminder, or message that pushes her toward reporting.

## Open decisions

| # | Decision | Detail | Owner |
|---|---|---|---|
| 1 | Entry-use control: UI and default | PROVISIONAL. The founder's starting choice on 7 Nov 2026; it may change, so keep it swappable. Default: all uses on, because the brief's tell-it-once flow needs later stages to draw on what she wrote. UI: a quiet tappable line under each entry in the Write chat shows where it is used (personal timeline, legal guidance, report). Tapping opens a small sheet with three switches. Nothing to fill in when she sends, and she can change it any time. Turning off personal timeline hides the entry from the timeline; it stays stored and can still be deleted. Extraction still runs on every new entry, because that is how the timeline is built. The privacy text says so (`SAFETY.md` holds that text). | team |
| 2 | "What matters most" step | The brief records this as a recommendation of the research notes. It is not in the 7 Nov build list. Not built unless the team confirms. | team |
| 3 | Language | DECIDED: Indonesian for the UI and for AI replies, with "kamu/aku". No EN/ID toggle. | team |
| 4 | Disguise: access mechanism and cover contents | DECIDED (C11, 7 Nov 2026). Visible app name: Eira. Cover: working to-do list. Adding a new task named exactly `eira` opens the actual app and does not save a cover task. Other titles create ordinary tasks. No secret-name setup. Each diary entry creates one unrelated cover task with no entry link. The fixed access title is not an encryption secret; C13 uses a device-held key with no extra passphrase. Neither the name nor icon may contain the banned words. | team |
| 5 | How does the AI reply in Stage 1? | DECIDED: the AI replies in the chat. OPEN: how it replies (what the reply says, how long it is, its wording rules, and whether it can see earlier entries). The team is working on it. Build default, so work is not blocked: see `AI_CONTRACTS.md` call 1 (`reply` field). | team |
| 6 | How her Stage 2 messages are stored | DECIDED: the default stands. The brief says the report draws on what she said while asking. Default: store them as entries marked as questions, not extracted into the timeline, usable as report sources only if allowed for report. | team |
| 7 | Whether the FAQ has 11 or 12 answers | See `LEGAL_FAQ.md`. OPEN. Legal research in progress, see docs/LEGAL_REVIEW_LOG.md. | team |
| 8 | Modified Abuse Monitoring at OpenAI | Needs OpenAI approval. Ask organisers on the day. | team |
| 9 | After the event: KemenPPPA agreement | DECIDED: the team accepts this. Get KemenPPPA's agreement before the real target is used by anyone outside the team. Not a task for the hackathon day. | team |
