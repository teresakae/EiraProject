# Cover and Write work log

## 7 Nov 2026 — documented passphrase decision

Asked to own the cover, secret access, encrypted storage, Write and voice, keeping server, Ask and Report screens untouched. Implementation paused because key management was OPEN. The owner then approved updating the flow: open app → add task exactly `eira` → create her own private passphrase → open the real app. Later visits require that passphrase, with no automatic unlock.

Updated PRODUCT C12, the brief, architecture, safety, build plan, agent instructions and access/deletion/background fixtures to reflect this decision. The example `passkey` is not a default credential. Passphrase setup is required access setup, separate from optional onboarding.

Built: documentation only; no application code changed.

Validation: checked active documentation for obsolete OPEN key-management statements and direct-open access wording. B1, CV1, DL1, DS1, A1, N1, Q1, Q5 and R1 were not run; no implementation pass is claimed. Earlier base logs remain historical records of the decision at that time.

Shared-model changes: none. No git operations performed.

Added `docs/COVER_HANDOFF.md` at the owner’s request so this documentation checkpoint can be pushed before implementation resumes. It includes the approved flow, current base status, unrun fixtures, ownership boundaries and a copyable continuation prompt. The referenced `CODEX_PROMPTS.md` is absent; the handoff records that gap.

## 7 Nov 2026 — implementation on main and local server connection

The owner supplied the handoff and this checkpoint from Downloads, authorized work directly on `main` in `/Users/kaes/Documents/Personal/Eira`, and approved proceeding with the reviewed implementation plan. No branch, commit, push, merge or history change was made. The different inner-repository path is not present here. The supplied handoff's branch-preparation instruction is superseded by the owner's direct request. This checkout lacked C12 and the two handoff files; the active requirements were reconciled with the owner-approved passphrase policy. The imported documentation-only checkpoint above is historical, not a claim about the starting files in this checkout.

### Built

- Persistent cover tasks and a separate AES-GCM encrypted private envelope behind `EiraStore`. Private data includes entries, events, Write replies and report drafts. Cover tasks contain no private entry link.
- A random 256-bit data key, wrapped with a key derived from her exact passphrase using CommonCrypto PBKDF2-HMAC-SHA256, 600,000 rounds and a random 32-byte salt. Version, salt, wrapped key and ciphertext live together in the encrypted-store envelope. Neither the passphrase nor an automatically usable key is saved. Encryption uses fresh CryptoKit GCM nonces. Wrong passphrases and malformed envelopes do not replace existing files.
- Both files use complete iOS file protection and atomic writes; the containing directory is excluded from backup. Deletion removes the private envelope, including salt and wrapped key, while leaving cover tasks unchanged. New access then requires fresh setup.
- A working native to-do cover; only the unmodified title `eira` starts access, consuming it without saving a task. First access creates her own passphrase; later access requires it again. No default, recovery, biometric unlock or credential saving.
- Inactive rendering substitutes the cover. Background locking removes the private workspace, drops the store's records and key references, clears Write input and cached Ask/Report content, cancels HTTP requests and recording, and invalidates the old store session. Late results cannot write into a later unlock or a fresh store after deletion. Ask and Report screen files were not edited; their core flows received only lock cleanup/late-result guards.
- Write saves exact text and phone time, validates every returned event quote, shows the reply separately under her message, displays timeline quotes/injuries/witnesses, and lets her edit violence types. The all-on default stays in `EntryUseDefaults`; the three-switch UI lives in `AllowedUsesControl`. Allowed-use changes made while extraction is pending are preserved. AI replies never enter quote-source text or request entry text.
- Voice records to a protected temporary m4a, transcribes into editable input, and deletes the file on success/failure/cancellation. It does not send the transcript as an entry automatically. The 4,000,000-byte limit matches the owner-approved server contract.

Cryptographic parameter references: [OWASP password storage guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html), [Apple CryptoKit AES-GCM](https://developer.apple.com/documentation/cryptokit/aes/gcm). These choices are implementation details, not a completed independent security review. Swift/CryptoKit object references are released on lock; no forensic zeroization of every runtime or OS copy is claimed.

### Server request added by the owner

The owner supplied `http://127.0.0.1:3000` and requested all four endpoints from `server/README.md`. `HTTPServerClient` now sends authenticated POST requests for extract, Ask, draft and multipart transcription, using an ephemeral session without persistent cookies/cache and rejecting redirects. Requests contain the existing typed contracts, with no prompts or OpenAI key. HTTP is accepted only for loopback in a Debug simulator; other builds require HTTPS.

Only `EIRA_APP_TOKEN` was selected from `server/.env.local`. Its value is not recorded here. The generated local configuration is `.build/LocalServer.xcconfig`, with file permissions 0600, included optionally by the existing build configuration. Both token and loopback address apply only to Debug simulator builds. `.build/` and `server/.env.local` are ignored. The generated Debug plist was checked for the expected address/token; the Release plist contains neither. The token was checked absent from tracked diffs and unignored new files. The OpenAI key remains server-only. No files under `server/` were edited.

If `.build/` is removed, the local configuration must be recreated from the server token. A physical phone needs an HTTPS deployment address; it cannot use this Mac's loopback address. Canned responses remain available for unit tests and previews. The running simulator app uses HTTP, not canned responses.

### Verification

Debug and Release simulator suites: **46 tests, 45 passed, 1 opt-in live test skipped, zero failures in each configuration**. The skipped test was then run separately with live checks enabled and all four endpoints passed. Release tests did not enable local/live calls or open a real submission form.

The first run exposed a missing Codable key for the new Write reply; it was fixed and persistence now passes. A cache-cleanup test initially used a free-text value for a dropdown; the invented fixture was corrected to a text field. The final suites pass without source warnings; Xcode emits its standard unused AppIntents metadata warning.

| Fixture/check | Observed result |
|---|---|
| B1 | Automated inactive/lock state, cleared private workspace/input/caches, wrong/correct later unlock and no automatic unlock pass. Actual app-switcher image and lifecycle timing remain visually unverified. |
| CV1 | Exact entry, validated event, persisted reply, unrelated task with no entry ID/text, and task access while locked pass. |
| DL1 | Private envelope removed; tasks unchanged; fresh passphrase setup required; entries/events/draft empty; old session rejected after fresh setup. |
| DS1 | Exact lowercase `eira` consumed; `Eira`, leading/trailing-space variants and ordinary titles remain ordinary tasks. Locked cover add/complete/delete passes. |
| A1 | Temporary-file deletion passes on successful and forced-failed transcription. Synthetic invented Indonesian audio also succeeded through the real transcription endpoint. Actual microphone interaction and mixed-language quality remain unverified. |
| N1 | New UI/copy reviewed for reporting nudges; no counts/streaks/progress toward reporting. Existing Ask/Report rendering checks pass. Live M1 reply gives no verdict or reporting/leaving/staying nudge. Visual review by the owner remains. |
| Q1 | Five invented reply-as-quote cases dropped; existing normalization/field tests pass. Replies remain separate from her text. |
| Q5 | Canned M1/X1 add no unsupported names/events; live M1 returns the three expected forms with validated source quotes. This is not a general guarantee of model quality. |
| R1 | Persisted reply is separate from her words and rendered under her message. Live M1 reply is Indonesian, refers to her stated injuries and gives no verdict/nudge. |
| Additional | Independent PBKDF2 SHA-256 vector, encrypted round trip, unchanged ciphertext after wrong passphrase, corrupt-store refusal, permission changes during extraction, and late-response rejection pass. |

Final live M1 run returned **3 events**: physical, psychological and neglect, each with a validated quote. Reply: “Kepala kamu sampai kebentur lemari dan pipi masih bengkak. Kamu mau cerita bagian mana yang paling mengganggu sekarang?” Cover task: “Rapikan Jadwal Kegiatan”. Ask returned: “Aku belum bisa menjawab pertanyaan ini. Kalau kamu mau, kamu bisa menanyakannya ke LBH APIK.” Draft decoded all 17 fields. An invented synthetic clip returned nonempty transcription text. No real person's words or real submission target were used.

Simulator UI automation could not select Simulator by name or bundle ID, so no visual pass is claimed. The Debug app was installed/launched on iPhone 17 Pro (`CDEBB40E-648A-457A-8B41-C58E0DDE7100`) for the owner's manual checks. No credential was created in that normal app session. Real-device backup exclusion, keyboard learning, Spotlight/Siri, app-switcher snapshots, microphone operation and human voice-quality review remain unverified. On extraction failure, her exact entry remains encrypted; missing AI output is not fabricated or automatically retried.

### Shared-model and contract changes

- `Entry.writeReply: String?`, encoded as `write_reply`, stores AI text separately from immutable `Entry.text`; older entries decode without it. No changes to `AllowedUses`, `Event`, `ReportDraft`, `ReportDraftField`, `ReportValue` or `CoverTask`.
- `EiraStore` record-access contract is unchanged. `PrivateSessionStore` enforces one-unlock access behind that contract.
- `ServerClient` adds `cancelPendingRequests()` with a no-op default for canned/test clients; HTTP cancels outstanding requests on lock.
- Shared bootstrap/config changes: `AppDependencies` gains optional session-cleanup lifetime; the app mounts the private stages behind access; Info.plist gains microphone text and server settings; the existing xcconfig optionally includes ignored local settings. `EIRA_RELEASE_REPORT_TARGET` is unchanged. Ask/Report screens and server files are unchanged.

## Notes cover design — 7 Nov 2026

Owner approved replacing the task cover with the supplied Notes design, keeping exact `eira` access, and building the PIN screen for later backend integration (PRODUCT C15). Implemented searchable note cards, pinning, text/checklist editor, and amber cover styling. Existing task JSON still decodes; legacy tasks become editable single-item checklists without rewriting data at launch. New cover fields are optional and stay in the separate cover file. No private content is used for note previews. Saving exact `eira` calls the existing access flow and does not store that title.

`CoverPINScreen` is standalone with `onCancel` and `onSubmit(String)` callbacks; it has no current route from the cover, no PIN persistence, and no verification. C13 access and encryption are unchanged. Attachments and photos remain excluded.

Validation: Debug simulator build passed. Both CoverDesignTests passed: legacy decoding, note/checklist/pinning persistence, cover deletion without unlocking private storage, and render captures for home, editor and PIN. Reviewed captures and adjusted checklist spacing and amber back control. The wider suite's previously observed Keychain/migration failures were not re-investigated in this visual change.
