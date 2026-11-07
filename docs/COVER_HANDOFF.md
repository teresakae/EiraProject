# Cover, access, storage and Write handoff

Current workspace note: the owner supplied this checkpoint from Downloads and then explicitly authorized implementation on `main` in `/Users/kaes/Documents/Personal/Eira`. The branch-preparation instruction below is superseded by that request. This imported checkpoint described documentation not present in this checkout; the current implementation log records reconciliation and actual test results.

Checkpoint: 7 Nov 2026. Documentation only. The owner requested this checkpoint before pushing the current state. No application implementation was performed in this chat, and no commit, push, branch creation or merge was performed. The last inspected checkout was `main`; the owner prepares the implementation branch.

## Approved flow

1. Open Eira: show the working to-do cover.
2. Add a task named exactly `eira`: consume the trigger without storing a visible task.
3. First entry: prompt her to create her own private passphrase, then open the real app.
4. Later entries: prompt for that passphrase; only the correct one opens her records. Never unlock automatically or prefill credentials.
5. Hide private content when inactive; lock on background and drop the unlocked key and decrypted records from memory. Return to the cover.
6. Delete everything removes private records and their key material, preserving cover tasks. The next access starts fresh passphrase setup for an empty store.

The owner called the typed secret a “passkey”, using “passkey” as an example. Documentation calls it a **passphrase** to distinguish it from Apple/WebAuthn passkeys. The example is not a default credential. There is no passphrase recovery; forgetting it means losing access to existing records. The fixed trigger and OpenAI API key must never serve as storage encryption keys. The API key stays in the server environment.

PRODUCT C12 records this decision. C11 still defines the to-do cover and unrelated generated tasks. The entry-use default and three-switch sheet remain PROVISIONAL. Optional onboarding remains out of scope; required passphrase setup is part of access.

## Current implementation and verification

The repository contains the shared base: models, quote checks, an in-memory store, canned client and separate screen files. Only the cover is mounted. The real encrypted store, access flow, Write flow and recording are not implemented by this checkpoint. Existing source files were not changed.

Updated documentation: `AGENTS.md`, `docs/BRIEF.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/SAFETY.md`, `docs/BUILD_PLAN.md`, `docs/FIXTURES.md`. Added `docs/codex-log-cover.md` and this handoff. Historical base logs retain their original status; C12 is the current decision.

No build or runtime fixtures were run for this documentation-only change. B1, CV1, DL1, DS1, A1, N1, Q1, Q5 and R1 remain to be verified against the implementation. No shared models changed.

Documentation gaps to keep visible: `BUILD_PLAN.md` references `CODEX_PROMPTS.md`, which is absent from this checkout; use the prompt below for this handoff. The cryptographic derivation parameters and storage format have not been implemented or validated. C12 approves the user-facing passphrase policy, not a completed security review. Do not introduce recovery, biometric unlock, credential saving or additional screens beyond the approved flow.

## Prompt to resume implementation

Copy the following into the next coding chat after the owner prepares the working branch:

```text
You own Eira's cover, secret access, encrypted store, Write stage and voice (Person B). Resume from docs/COVER_HANDOFF.md and docs/codex-log-cover.md. This is a shared-base checkout with an approved documentation update, not a finished feature implementation.

Read AGENTS.md, docs/BRIEF.md, docs/PRODUCT.md, docs/ARCHITECTURE.md, docs/SAFETY.md, docs/BUILD_PLAN.md, docs/FIXTURES.md, and call 1, call 4 and quote check in docs/AI_CONTRACTS.md. Brief plus PRODUCT's changes table govern scope. C12 is DECIDED: first exact eira task opens private passphrase creation; later entries require that passphrase. No automatic unlock. No default passphrase. No recovery. Do not reopen this already-approved product decision.

Inspect the existing code and working tree before editing. Explain the concrete implementation plan in plain language and obtain the review required by AGENTS.md before new application files or broad code changes. The owner handles git: never commit, push, create a branch, merge or change history. If still on main, ask the owner to prepare the implementation branch. Do not edit server/ or the Ask and Report screens. Only you may change shared data models; requests from other agents must come through a person. Coordinate shared bootstrap/configuration changes with the owner.

Build in this order:
1. AES-GCM encrypted secret store and separate cover store behind the existing store interface, using her passphrase to protect access to the secret key. Keep key handling separate from trigger handling. Apply iOS file protection and secret-store backup exclusion. Never save her passphrase or provide automatic unlock. Wrong passphrases must not expose or replace existing records.
2. Working to-do cover, exact eira trigger, required first-entry passphrase setup, later passphrase unlock, hide on inactive, lock on background, and delete everything preserving cover tasks. Keep cover, access and passphrase UI in separate files. Drop unlocked key and decrypted records on lock; prevent late async responses from restoring deleted or locked private state.
3. Write: exact typed entries and phone time, canned extract, timeline with quotes, quote check for every event, editable violence type marked as hers, unrelated generated cover task, allowed uses per entry, AI reply under her message. Replies are never quote sources. Keep the all-on default in one setting and three-switch control UI in one component. No plant notes or plant-name setup.
4. Voice last: record, transcribe into editable input, delete temporary audio on both success and failure. Continue using canned server responses until the real server is merged. No third-party libraries or notifications.

Use invented fixtures only. Verify B1, CV1, DL1, DS1, A1, N1, Q1, Q5 and R1, including first passphrase setup, correct/wrong later unlock, no automatic unlock, and fresh setup after deletion. Use the build/test commands in AGENTS.md; never reach the real submission target with test data. Distinguish automated checks from device checks and untested behavior.

Keep docs/codex-log-cover.md updated with what was asked, what was built and fixture outcomes. Finish by listing all shared-model changes. If required behavior is missing or documents conflict, stop and ask the owner instead of inventing scope.
```
