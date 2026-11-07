# Eira: AI contracts

Prompt text is written on the day with Codex. Prompt tone is still being tuned by the team; the direction is in "Voice: sounding human, not like a chatbot" below. This file gives purpose, inputs, outputs and rules, plus must-fail tests in `FIXTURES.md`. It does not give final prompts.

## Models and API settings (DECIDED)

The team accepted these models.

| Job | Model | Reasoning | Notes |
|---|---|---|---|
| Extraction (call 1) | `gpt-6-luna` | `none` | Primary. Cheap and fast. |
| Ask (call 2) | `gpt-6-luna` | `none` | Primary, with Terra as fallback. |
| Report drafting (call 3) | `gpt-6.1-terra` | `none` | Also the fallback if Luna fails. |
| Voice (call 4) | `gpt-transcribe` | Not applicable | File route: record, upload, get text. |

Reasoning is `none` to start. Raise it only if quality is poor. Check the model names on the OpenAI dashboard before the build, because the lineup changes quickly. The results of rehearsal tests T1 to T7 are not recorded in our notes. If Luna fails T3 or T4, swap the order. If only Terra passes extraction, Terra becomes primary.

Settings for every text call:

1. Use the Responses API.
2. Use Structured Outputs in strict mode. Every object has `additionalProperties: false`. Every property is listed as required. "Optional" means the type allows null.
3. Check for a refusal before reading the result. A refusal arrives as a content item of type refusal, not as JSON. A refusal on abuse content is a serious finding: note it and try Terra (see `FIXTURES.md`).
4. `store: false`. No `previous_response_id`. The app sends the whole conversation each time.
5. Set a maximum output size, and handle an "incomplete" result by raising it or failing cleanly.
6. A plain loop tries the primary model, then the fallback. This loop is our own code.
7. Numeric limits on a property (such as age 1 to 100) may be rejected by strict mode. UNVERIFIED. If rejected, drop the limits from the schema and check the number in app code.
8. Send no identifier tied to a person.
9. Use invented messages when testing. Never a real woman's words.

## Call 1: Extract events and a cover task

Purpose: turn one entry into timeline events, one unrelated, ordinary cover task, and a short reply to her.

Input: the text of the new entry only.

Output:

| Field | Type | Rule |
|---|---|---|
| events | list | One item per distinct event. Several events in one entry give several items. |
| events.when_text | text or null | When, exactly as she wrote it (for example "last night around 11"). Null if not mentioned. |
| events.what_happened | text | One or two sentences, in her words. |
| events.injuries | text or null | Physical effects she mentioned. Null if none. |
| events.witnesses | list of text | Empty if none. |
| events.quote | text | An exact substring of the entry text. |
| events.pkdrt_type | one of five values | `fisik`, `psikis`, `seksual`, `penelantaran`, `tidak_yakin`. |
| cover_task | text | One unrelated, ordinary task title. See cover task rules. |
| reply | text | In Indonesian. A short reply shown in the chat under her message. See reply rules. Default until the team settles how replies work. |

Rules:

1. Use only what she wrote. Do not guess. If a detail is not mentioned, it is null.
2. Never invent a name (for example for the husband).
3. Keep `when_text` as she wrote it. Never convert it to a calendar day. The timeline date comes from the entry's phone time. This is the T2 pass criterion.
4. `quote` must be copied letter for letter. After the call, plain code runs the quote check. An event that fails is dropped.
5. `pkdrt_type`: if the entry is unclear, use `tidak_yakin`. A wrong confident tag is worse than "not sure". The tag is a suggestion she can edit.
6. Cover task: an ordinary to-do title unrelated to the entry. No people, no feelings about home, no abuse words, nothing from the entry's content. Never return the reserved access title `eira`. It is stored in the cover task list without an entry id or source marker (C11).
7. A mixed entry (for example a slap and an insult together) should give two events or two tags, not one.

### Reply (default until the team settles how replies work)

That the AI replies in Stage 1 is DECIDED. How it replies is OPEN (open decision 5 in `PRODUCT.md`). The `reply` field and the rules below are the build default, so the build is not blocked. Expect them to change.

1. Write in Indonesian, using "kamu" for her and "aku" for the app.
2. Add no fact she did not write. No new detail, name, date, or event.
3. Never give a verdict. Never say someone committed a crime or is a perpetrator.
4. Never nudge her toward reporting, leaving, or staying.
5. The reply is AI-written text. It is never a quote source and never goes into the quote check as a source.
6. OPEN: whether the reply can see earlier entries. Default: it sees the new entry only, which matches the input above.
7. OPEN: the exact reply wording (tone, length, what it may say). The direction is set in "Voice: sounding human, not like a chatbot" below; the team tunes the final wording and examples. Do not invent final copy. Keep the reply short and plain.

## Call 2: Ask

Purpose: answer her question about what the law means for her, using the approved FAQ and her allowed entries.

Input: her question and the Ask chat so far (whole conversation each time); the approved FAQ text, which is `FAQ_APPROVED.md` only (held on the server) and only the slots that have approved text; entries allowed for legal guidance, with their events. Never entries limited from legal guidance.

Output (default shape, confirm on the day):

| Field | Type | Rule |
|---|---|---|
| answer | text | In Indonesian. Plain language. |
| faq_answers_used | list of numbers | Which FAQ answers the reply relies on. Lets plain code add the lawyer caveat. |
| articles_named | list of text | Articles named, as information. Can be empty. |
| not_sure | true or false | True when an entry is unclear or the FAQ does not cover it. |

Rules:

1. Ground the answer in the approved FAQ (`FAQ_APPROVED.md`) and her allowed entries. Do not add legal claims beyond them.
2. The server loads only `FAQ_APPROVED.md`. It never loads `LEGAL_FAQ.md` or `LEGAL_REVIEW_LOG.md`, and neither is bundled with the server. A slot with no approved text does not exist for the AI.
3. If her question falls on an answer that is not approved, or the approved FAQ does not cover it, the AI says plainly that it cannot answer that yet and hands off to a human service. It does not improvise law and does not use any unapproved text.
4. If nothing is approved, Ask still runs. Every question gets the plain "cannot answer yet" and the hand-off.
5. If `faq_answers_used` includes 4, 7 or 11, plain code adds a visible caveat that a lawyer has not reviewed that part. The prompt alone is not enough.
6. Hand off to a human service when appropriate: SAPA 129, a legal aid group such as LBH APIK, or the regional unit UPTD PPA.
7. Never tell her to leave, to stay, or to report.
8. Never claim that Eira keeps her safe.

### Non-judging rules (C5)

Allowed:

- Name a possible form of violence that matches what she wrote.
- Explain what the relevant article says, as information.
- Give the general penalty range from the FAQ, framed as what the law provides in general.
- Say that the authorities and courts decide whether something meets an article.

Banned:

- Saying that her husband committed a crime, or is proven to have.
- Applying a sentence to her husband ("he can be jailed for X years").
- Telling her what the outcome of her case will be.
- Telling her to leave, stay, or report.

Illustrative Indonesian examples. These are not final copy. The team and a reviewer refine tone.

| Kind | Example | Meaning |
|---|---|---|
| Allowed | "Apa yang kamu tulis tentang ditampar bisa termasuk kekerasan fisik, yang dijelaskan di Pasal 6 UU PKDRT. Pasal itu hanya menjelaskan pengertiannya. Apakah suatu kejadian memenuhi pasal itu, yang memutuskan polisi dan pengadilan, bukan aplikasi ini." | What you wrote about being slapped could be physical violence, which Article 6 describes. The article only describes the meaning. Police and courts decide whether an event meets it, not this app. |
| Allowed | "UU PKDRT mengatur hukuman maksimum untuk kekerasan fisik di Pasal 44. Itu aturan umum. Hakim yang menentukan untuk setiap kasus." | The law sets a maximum for physical violence in Article 44. That is the general rule. A judge decides each case. |
| Banned | "Suamimu terbukti melakukan tindak pidana dan dapat dipenjara sekian tahun." | Your husband is proven to have committed a crime and can be jailed. (Based on the teammate's banned example.) |
| Banned | "Kamu sebaiknya melapor sekarang." / "Sebaiknya kamu pergi dari rumah." | You should report now. / You should leave the house. |

## Voice: sounding human, not like a chatbot

Status: DECIDED as direction. The team tunes the exact wording on the day.

This applies to every reply she reads: the Stage 1 reply and Ask answers. Sounding human comes down to three things: prompt rules, examples, and people judging the output. Rules alone are not enough.

Rules:

1. Answer her fear first, law second. If she asks "Will he be arrested?", give a direct answer before naming any article.
2. Use her words and history, for example "Kamu tadi cerita soal uang belanja". This is how the app keeps its tell-it-once promise. Our research notes report survivors asking domestic-violence chatbots for better empathy and memory (AinoAid). Only use entries that are allowed for that use. In Stage 1 the default is the new entry only (see Reply, rule 6), so this rule applies within that entry until the team settles how replies work.
3. Keep it short, one idea per turn, in chat-style sentences. No bullet lists, no headings, no dump of articles.
4. Match her register. Use casual "kamu" and "aku", the way she writes. Never formal "Anda".
5. Ban stock lines such as "Saya memahami perasaan Anda" and "Terima kasih sudah berbagi". Do not open every turn the same way.
6. Ask before advising, one question at a time. A 2026 audit of domestic-violence chatbots found that few asked follow-up questions before advising (Poveda et al., FAccT 2026, per our research notes).
7. Do not fake it. Never claim feelings or personal experience. Be warm, but honest that this is an app.
8. Warmth stays inside the non-judging rules (C5). "Itu bukan salah kamu" is fine. "Suamimu salah secara hukum" is a verdict and is banned.

Examples: put 3 to 5 good and bad exchanges in the prompt. Examples work better than rules alone.

TO FILL IN: 3 to 5 good and bad example exchanges, written by the Indonesian teammates. Codex does not write these and the doc does not give final copy.

Model: `gpt-6-luna` with reasoning off may read flat. If teammates judge it flat, try `gpt-6.1-terra` for Ask only. This is a team call on the day. The model table above stays as decided.

Where it lives: keep the voice rules and examples in the plain prompt files on the server, so a person can tune them without touching logic.

Tests: the voice tests are in `FIXTURES.md` (VO1 to VO7).

## Call 3: Draft the report

Purpose: fill the SAPA fields from her words.

Input: entries allowed for report (exact text), and her allowed Stage 2 messages. Never entries limited from report. AI-written text (the app's own answers) is never a source, because it is not her words.

Output: for each SAPA field in `SAPA_FORM.md`, a pair.

| Part | Type | Rule |
|---|---|---|
| value | the field's own type, or null | Null if not in her words. Dropdown values must be exactly as in `SAPA_FORM.md`. |
| quote | text or null | The words that support the value. An exact substring of one entry. Null if value is null. |

Rules:

1. No source, no field. If the value is not in her words, both value and quote are null.
2. Interpretive fields (for example `level_concern`) may have no possible quote. They stay empty for her to choose. This is the paraphrase trap (T4).
3. Do not choose `Tidak Diketahui` for time of day on her behalf. Leave it empty. She can pick it herself. (Default; the sources do not settle this.)
4. Plain code checks every pair with the quote check below, and rejects any dropdown value not in the allowed list.
5. Plain code sets `source_entry_id` from the entry where the quote was found.
6. `description` is a summary that can span several events, so one quote cannot support all of it. OPEN: the default for the build is the same pair as every other field, as tested in T4. The team may change this.

## Call 4: Transcribe

Purpose: turn a voice clip into text.

Input: the audio file, with an Indonesian language hint. The model takes a list of languages; how to encode that list in a raw request is UNVERIFIED, so use the SDK and check the API reference.

Output: text. It goes into the text input as her message. She can read it before it counts.

Rules:

1. The audio is deleted from the phone right after, whether or not the call worked.
2. The server keeps no audio.
3. Accepted formats include mp3, mp4, mpeg, mpga, m4a, wav, webm, up to 25 MB.
4. Transcripts may have odd spellings. The quote check compares against the exact text sent to the model, not what she said.
5. Quality for Indonesian mixed with Javanese is UNVERIFIED. Test T5 decides keep or drop. Drop voice if clip A (plain Indonesian) gets content words wrong (violence words, who, when). A wrong word in a report is worse than no voice.

## Quote check

Runs on the phone in plain code. It is not an AI call. Use it on call 1 events and call 3 report fields.

1. Take the quote and the text it must come from. For call 1, that is the entry text. For call 3, test each allowed entry text one at a time, so the source entry is known.
2. Normalise both strings. Apply Unicode NFKC. Make lowercase. Replace curly quotes with straight quotes. Remove every character that is not a letter, a digit or a space. Collapse runs of whitespace to one space. Trim.
3. If the normalised quote is empty, reject it. An empty string would match anything.
4. Test whether the normalised text contains the normalised quote as a substring.
5. If the value is present and the quote is missing, or not found, set the field to null (and its quote). For an event, drop the event.
6. If found, keep the field and record the entry that contained the quote.
7. Widen the normalisation only as far as needed. Look at what differs first (the model fixing spelling, an added word, a curly apostrophe).

Test cases are in `FIXTURES.md`: an invented quote is rejected (T4 A), a hand-corrupted quote is rejected (T4 B), a harmless difference (capital letters or a missing comma) is accepted (T4 C).

## Legal article map

Source: our research notes, with Pasal 8 from the test plan's "Pasal 6 to 9" reference. The research notes also list Pasal 8 as sexual violence. All pending lawyer review. The law is UU PKDRT (UU 23/2004). Pasal 5 lists the four kinds.

| pkdrt_type | Article defining it | Penalty article |
|---|---|---|
| `fisik` | Pasal 6 | Pasal 44 |
| `psikis` | Pasal 7 | Pasal 45 |
| `seksual` | Pasal 8 | Pasal 46 |
| `penelantaran` | Pasal 9 | Pasal 49 |
| `tidak_yakin` | None | None |

Penalties are general information from the approved FAQ. They are never applied to her husband. Penalty figures come only from approved text in `FAQ_APPROVED.md`; answer 4 (which covers penalties) is flagged for lawyer review. If answer 4 is not approved, the AI gives no penalty figures.
