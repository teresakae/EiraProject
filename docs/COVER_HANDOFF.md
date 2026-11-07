# Cover, access, storage and Write handoff

Current requirements: `PRODUCT.md` C11 and C13. The owner approved direct access
and device-held encryption on 7 Nov 2026. `docs/codex-log-merge.md` records the
integration checks and remaining human/device checks. The owner handles all git
operations; work stays in the supplied checkout.

## Approved flow

1. Open Eira: show the working to-do cover.
2. Add a task named exactly `eira`: consume it without storing a visible task and
   open the private area directly. No passphrase setup or normal unlock screen.
3. Keep entries, events, replies and drafts encrypted with AES-GCM. The random
   key stays in this phone's non-syncing Keychain and is available only while the
   phone is unlocked. The trigger and server API key are never encryption keys.
4. Existing passphrase-protected records require one correct unlock to convert
   without deleting entries, events, drafts or cover tasks. Wrong phrases,
   malformed records and missing device keys must not replace stored records.
5. Hide private content when inactive. Backgrounding drops decrypted records and
   the in-memory key and returns to the cover; the next exact trigger opens it.
6. Delete everything removes private records and their device-held key, preserves
   cover tasks, and makes the next trigger open an empty private area.

Anyone using the unlocked phone who knows `eira` can open the private area. The
privacy text states this limit. No recovery, biometrics or extra access screens
are in scope. The conversion screen exists only to preserve existing records.

## Shared implementation

`AccessFlow` mounts the private workspace. Write, Ask and Report use the same
`PrivateSessionStore` and HTTP client. Old sessions cannot write after locking,
deletion or reopening. Write's exact entry text remains separate from AI replies.
Ask question permissions use the shared control; question entries are never
extracted into timeline events. Canned clients and in-memory stores are for tests
and previews.

Use `AGENTS.md` for current build/test commands. Keychain tests require signed
simulator builds; ad-hoc signing is sufficient. Use invented fixtures only. Debug
must use the mock form. Never load or fill the real target with test data.

No additional product behavior or visual design is authorized by this handoff.
