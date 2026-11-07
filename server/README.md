# Eira server

Four POST endpoints. No database, submission endpoint, accounts, or stored records.
The OpenAI key, prompts, strict schemas, and approved FAQ stay on the server.

## Local setup

Use Node 24. From the repository root:

```sh
cd server
npm ci
cp -n .env.example .env.local
```

Edit `.env.local`: set `OPENAI_API_KEY` and `EIRA_APP_TOKEN`. The token must be a
separate random secret shared with the app. This workspace already has a generated
token. Never use the OpenAI key as the app token. Neither secret belongs in git.

```sh
npm start
```

Local address: `http://127.0.0.1:3000`. Stop with Control-C. A simulator on this Mac
can reach that address; a physical iPhone cannot reach this loopback listener.
Use the deployed HTTPS address for a phone. Do not send private text over HTTP.

## OpenAI platform setup

Create an Eira API project, enable API billing or hackathon credits, and create
a project API key (a service-account key for the deployed application). Allow
model requests for Responses and audio transcription. Check project access to:

- `gpt-6-luna`: extract and Ask, reasoning `none`.
- `gpt-6.1-terra`: report drafting and fallback, reasoning `none`.
- `gpt-transcribe`: voice, with SDK `languages: ["id", "en"]` (Indonesian and English).

Set spending limits and alerts in the platform. Model availability is project
specific. Ask the organisers about Modified Abuse Monitoring; `store: false`
does not itself remove abuse-monitoring retention. Prompts and schemas are local
server files, not dashboard objects. No Assistant, vector store, fine-tuning,
Realtime session, or uploaded Files API resource is needed.

Official references: [API keys](https://developers.openai.com/api/docs/guides/api-keys),
[models](https://developers.openai.com/api/docs/models),
[spending limits](https://developers.openai.com/api/docs/guides/spend-limits),
[data controls](https://developers.openai.com/api/docs/guides/your-data),
[transcription](https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create).

## Environment variables

| Variable | Meaning | Default |
|---|---|---|
| `OPENAI_API_KEY` | Server-only project API key | Required for model calls |
| `EIRA_APP_TOKEN` | Shared token the app sends | Required; fail closed if absent |
| `OPENAI_TEXT_MODEL` | Extract and Ask primary | `gpt-6-luna` |
| `OPENAI_FALLBACK_MODEL` | Fallback and draft model | `gpt-6.1-terra` |
| `OPENAI_TRANSCRIBE_MODEL` | Transcription model | `gpt-transcribe` |
| `PORT` | Local listener port | `3000` |

The app needs the HTTPS server address and app token only. Never the OpenAI key.

## Common HTTP contract

Every endpoint requires `Authorization: Bearer <EIRA_APP_TOKEN>`. Text endpoints
take `Content-Type: application/json`; transcription takes multipart form data.
All success and error responses are JSON with `Cache-Control: no-store`.
Only POST is supported. JSON requests are limited to 1,000,000 bytes.
No request may include client prompts, schemas, person IDs, or extra keys.

The app filters entries by allowed use **before sending**. The existing request
shapes contain no use flags, so the server cannot recover that consent decision.
Send only conversation messages allowed for legal guidance. Assistant messages
are context only, never facts or quote sources.

### POST `/api/extract`

Request:

```json
{"text":"<the new entry only>"}
```

Response:

```json
{
  "events": [
    {
      "when_text": null,
      "what_happened": "<her words>",
      "injuries": null,
      "witnesses": [],
      "quote": "<substring of the entry>",
      "pkdrt_type": "tidak_yakin"
    }
  ],
  "cover_task": "<ordinary unrelated task>",
  "reply": "<short Indonesian reply>"
}
```

`when_text` and `injuries` are string or null. `witnesses` is a string array.
`pkdrt_type` is `fisik`, `psikis`, `seksual`, `penelantaran`, or `tidak_yakin`.
Events whose quotes fail provenance checking are dropped. The phone also checks
quotes and supplies its own date. The reply is never a quote source. A rejected
cover task causes fallback; it is never returned to the cover.

### POST `/api/ask`

Request:

```json
{
  "question": "<current question>",
  "conversation": [
    {"role":"user","text":"<previous allowed question>"},
    {"role":"assistant","text":"<previous answer, context only>"}
  ],
  "entries": [
    {"text":"<exact allowed entry>","events":[]}
  ]
}
```

`events`, when present, uses exactly the extract event shape above. All three
top-level keys are required; arrays can be empty. `question` is the new question,
not duplicated in `conversation`. No entry IDs or timestamps are sent.

Response:

```json
{
  "answer":"<short Indonesian answer or hand-off>",
  "faq_answers_used":[],
  "articles_named":[],
  "not_sure":true
}
```

`faq_answers_used` contains approved answer numbers actually used. Unknown answer
numbers fail validation. Named articles must appear in the cited approved text.
With no approved answers, the server makes no model call: it returns a plain
cannot-answer-yet hand-off with empty source/article arrays and `not_sure: true`.
If a model uses no approved source, its answer is replaced with that hand-off.
Plain code appends the caveat from `prompts/caveat.txt` for answers 4, 7 or 11.
There is no additional caveat property; the caveat is in `answer`.

Only nonempty `Approved text:` slots without `TO FILL IN` are loaded from
`docs/FAQ_APPROVED.md`. The header, metadata and unfilled questions are not sent.
Only the team edits that source file. Local calls reread it; after approvals
change, rebuild and redeploy the deployment package.

### POST `/api/draft`

Request:

```json
{"entries":["<exact allowed story>"],"questions":["<her allowed Ask message>"]}
```

Both arrays are required. Do not include any AI replies. Response has **all 17
fields at the top level**, with no `fields` wrapper:

```json
{
  "is_victim":{"value":null,"quote":null},
  "level_concern":{"value":null,"quote":null},
  "relationship_with_victim":{"value":null,"quote":null},
  "incident_time":{"value":null,"quote":null},
  "location":{"value":null,"quote":null},
  "province_city":{"value":null,"quote":null},
  "description":{"value":null,"quote":null},
  "korban_fullname":{"value":null,"quote":null},
  "korban_gender":{"value":null,"quote":null},
  "korban_age":{"value":null,"quote":null},
  "korban_disabilities":{"value":null,"quote":null},
  "korban_disabilities_type":{"value":null,"quote":null},
  "korban_contact_number":{"value":null,"quote":null},
  "korban_trusted_person":{"value":null,"quote":null},
  "reporter_fullname":{"value":null,"quote":null},
  "anonymous":{"value":null,"quote":null},
  "contact_number":{"value":null,"quote":null}
}
```

`value` is string or null, except `korban_age` (integer 1–100 or null),
`korban_disabilities` and `anonymous` (boolean or null). `quote` is string or null.
Dropdown values exactly follow `docs/SAPA_FORM.md`, encoded in `lib/schemas.js`.
Missing or unsupported quotes clear both parts. Invalid ages, telephone numbers,
overlong values and inferred concern are cleared. Unknown time stays null instead
of the model choosing `Tidak Diketahui`. The phone sets `source_entry_id`, applies
its quote check, and preserves her edits; these are not server response fields.
Drafting never submits anything.

### POST `/api/transcribe`

Multipart fields:

| Field | Type | Requirement |
|---|---|---|
| `file` | One audio file, with filename and content type | Required |
| `language` | `id` | Optional compatibility field for existing app builds; server always supplies both Indonesian and English hints |

Supported filename extensions: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, `webm`.
Maximum **4,000,000 bytes** of audio; maximum 4,100,000-byte multipart request.
This cap was approved by the owner for Vercel's 4.5 MB request limit.

Response:

```json
{"text":"<transcribed text for her to review>"}
```

Audio stays in request memory only, including on failure. No temp file or Files
API upload is created. The outgoing filename is neutral. The iOS voice owner must
delete the phone's temporary file on success and failure. This server does not
have access to that file and cannot verify the phone's deletion.

### Error response

```json
{"error":{"code":"model_unavailable","message":"<short Indonesian message>"}}
```

| HTTP status | Codes |
|---|---|
| 400 | `invalid_request`, `invalid_audio` |
| 401 | `unauthorized` |
| 404 | `not_found` (local runner) |
| 405 | `method_not_allowed` (`Allow: POST`) |
| 413 | `request_too_large`, `audio_too_large` |
| 415 | `unsupported_media_type` |
| 502 | `model_unavailable`, `transcription_unavailable`, `service_unavailable` |
| 503 | `server_not_configured` |

SDK errors and raw refusals are never returned or logged. Text requests try the
primary model, retry a refusal once, then try the fallback (with one refusal
retry there too). Draft uses Terra. Incomplete or invalid outputs use fallback
or fail cleanly. SDK automatic retries are disabled so attempts stay bounded.
Logs contain startup information or model/operation/failure-kind/status metadata
only. Every text request sets `store: false`, no `previous_response_id`, bounded
output tokens, no person identifier, and a strict schema.

## Checks and team review

```sh
npm test
npm run test:live
npm run build
```

`npm test` uses mocks and invented text. It does not prove model quality.
`test:live` uses API credits and the samples from `docs/FIXTURES.md`, plus an
invented FAQ created only inside the test setup. It prints IDs, tagging labels
and results, never message bodies. Legal wording failures require prompt fixes,
not weaker assertions. Automated voice/wording checks are partial; VO7 requires
two Indonesian teammates to read the actual replies aloud. Prompt example slots
remain empty for them. Rerun voice checks and VO7 after prompt changes.

See `docs/codex-log-server.md` for observed fixture results and outstanding checks.

## Vercel package

`npm run build` creates `server/dist/`, an explicit allowlist containing API
handlers, shared server code, prompts, package files, Vercel configuration and
only the filled approved FAQ slots. It contains no `.env.local`, test fixtures,
iOS code or other legal documents. The runtime loads `data/FAQ_APPROVED.md` in
that package; local development reads the team's source file.

Deploy **only `server/dist/`** as the Vercel project root, using the Other
framework preset. Do not deploy the repository root or `server/` source tree.
The generated configuration uses an empty `public/` directory for static output;
the code, prompt files and FAQ are function resources, not public static files.
Set the five model/key/token variables from the table in Vercel's environment
settings. Use a neutral project/domain name such as `eira`, and supply the HTTPS
address plus the same app token to the iOS owner. Do not put private words in the
domain. Do not expose deployment source or logs publicly.

The shared app token is the documented hackathon-only access control, not real
user authentication. Hosting deployment, host logs and rate limits must be
checked before the demo. This task does not deploy or modify the iOS app.

Vercel references: [Node runtime](https://vercel.com/docs/functions/runtimes/node-js),
[payload limits](https://vercel.com/docs/functions/limitations).
