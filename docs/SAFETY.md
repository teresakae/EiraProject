# Eira: safety, privacy and banned claims

Sources are the research notes, as cited in the brief. Nothing here has been tested with survivors. Copy marked DRAFT is refined on the day.

## Threat model (iOS terms)

The likeliest threat is someone who unlocks the phone and scrolls, including in-laws glancing at it. Next are account access (her Apple ID or iCloud may be known to him) and dual-use apps such as find-my-phone or parental controls. Spyware cannot be defended against, and a disguise does nothing there. Eira keeps her data out of iCloud and device backup, and the privacy text states these limits. Two assumptions are labelled in the notes as assumptions, not measured facts: in-laws living with her (design assumption) and the husband checking her phone (threat-model assumption). No Indonesian prevalence data was found for either.

## What the disguise does and does not do

It lowers the chance of casual discovery. It does not stop a determined search, spyware, a controlled account, or a forced unlock. If he forces her to unlock the app, encryption does not help. Discovery can make things worse: finding a safety app can signal that she is seeking help, and the notes cite this as a way abuse escalates. No study measures how often disguised apps are found. Eira makes no stronger claim.

## The "he opens it" test

The cover must survive inspection. Someone who opens the app must see a working to-do list, not a static fake screen. Nothing on any cover screen mentions help, abuse, reporting, or the real app. C11 in `PRODUCT.md` records the cover and access decision: adding a new task named exactly `eira` opens the actual app; any other title adds an ordinary task. The fixed trigger is discoverable and is not an encryption secret. C16 replaces direct access: saving a note titled exactly `eira` opens the PIN screen, and the fixed PIN `1111` opens the private area. A random encryption key is held by this phone. Anyone using the unlocked phone who knows `eira` and the fixed PIN can open the records. Existing passphrase-protected records require one unlock to convert without erasing them. Deletion removes private records and the device-held key; later access opens an empty private area.

## Rules

1. Nothing visible outside the secret area says the Indonesian word for "report", KDRT or SAPA. That covers the app name, icon, notifications, cover screens, the server domain, and file names. The SAPA form web view is inside the secret area.
2. No notifications of any kind. No permission prompt.
3. Lock when the app goes to the background, and hide content when it goes inactive. The app-switcher snapshot shows the cover.
4. Delete everything is fast to reach and removes the secret store and any key material kept for it. The cover stays as it was.
5. No duress PIN or decoy mode.
6. Never auto-send. The app never presses the form's send button; she does. Never run the real target with test data. Debug builds use the mock, and the demo runs from the demo branch, which forces the mock. The real form is a real government intake.

## Privacy text (DRAFT copy)

The app must say, in plain words, where she can read it before she writes anything real:

1. What she writes is encrypted on her phone with a device-held key. Access requires a fixed PIN; anyone using the unlocked phone who knows `eira` and the PIN can open her notes.
2. To answer her or fill the draft, her text is decrypted on the phone and sent through our server to OpenAI.
3. OpenAI can keep prompts and answers in abuse-monitoring logs for up to 30 days. Our server keeps no copy.
4. Voice is turned into text and the audio is thrown away.
5. The disguise lowers casual discovery. It does not protect against spyware, shared accounts, or being made to unlock the phone.
The privacy text must never claim that nothing is kept anywhere. That is not true.

The Stage 1 timeline extraction always sends the new entry to the AI, because that is how the timeline is built. The privacy text must not suggest otherwise. (See open decision 1 in `PRODUCT.md`.)

## Reporting confirmation: content requirements (DRAFT copy)

Shown before the SAPA form web view opens (C4). It must say:

DRAFT: the corrected lines in the table below (With whom, Unknowns, Anonymity) are based on AI research, not lawyer-reviewed. Team to approve. Source: `LEGAL_REVIEW_LOG.md`, findings 2, 3 and 10, and section 5, answers 1 and 2.

| Topic | Content |
|---|---|
| What is shared | The fields the app is about to fill into the form, with the words each came from. Entries she limited from the report are not included. Nothing else leaves the app. |
| With whom | SAPA 129, run by KemenPPPA. It starts a referral to a regional service unit (UPTD PPA). It is not an arrest, and it is not itself a police report. But staff may come to where she is, and in high-risk cases the national service standard lets them work with police, neighbourhood officials (RT/RW) or security officers. A police report is the usual way a criminal case starts. For some offences police can act once they know about it, and other people can also report. DRAFT, based on AI research, not lawyer-reviewed. Team to approve. |
| She sends it | The app fills the form but does not send it. She presses the form's send button herself. |
| Unknowns | We do not know whether or when the service would contact her husband, because no rule on that was found. On paper, the national service standard sets response times: immediately for high risk, about 6 hours for medium, and within 3 days for low. Outreach visits are set at 1, 2 or 3 days. We do not know how fast the service answers in practice. The mediation the unit may offer is something she can refuse. DRAFT, based on AI research, not lawyer-reviewed. Team to approve. |
| Risks | Police often push settlement. Of 105 legal cases Komnas Perempuan tracked in 2025, 18 involved criminalising the wife. |
| Anonymity | The SAPA site has an anonymous option and says it keeps identity confidential, per FAQ answer 2. Confidential does not mean he can never find out. To get some help she will likely need to give her identity to the service. Its standard intake asks for name, address and contact details, and SAPA's own form asks for a phone number, so anonymous may not mean the service cannot reach her. If a court case starts, he would normally learn of it, because he is the other party in a divorce, and a criminal case or protection order also involves him. No source says her name can be kept from him. DRAFT, based on AI research, not lawyer-reviewed. Team to approve. |
| Tone | No urging. No "are you sure you do not want to report". It informs and lets her stop. (C8) |

## Banned claims

From our research notes' claims-to-avoid list, only those that apply to app copy or AI answers. If a banned claim appears in a draft answer or screen, fail it.

| Do not say | Why | Say instead |
|---|---|---|
| Eira keeps you safe. Eira reduces violence. | The best tested analogue reduced decision uncertainty but not violence. | Eira helps you understand your options and decide. |
| The disguise cannot be found. | No study. Experts warn disguised apps can be found. | The disguise reduces casual discovery, not a determined search. |
| Encryption protects you if he makes you unlock it. | Coercion beats encryption. | Say what encryption does not cover. |
| Nothing is kept anywhere. | OpenAI can keep abuse-monitoring logs for up to 30 days. | Our server keeps no copy. OpenAI may keep it up to 30 days. |
| Writing in the diary helps you heal. | Small or null effects in trials. | The diary is your own record. |
| A to-do list makes you safe. | No evidence. | The task list is a disguise against casual discovery only. |
| Reporting to SAPA gets him arrested. | SAPA refers to services. Police are a separate step. | SAPA connects you to help. Staff may visit, and in high-risk cases may involve police. Not automatic. |
| You need witnesses. | Her testimony plus one other valid piece of evidence is enough (Pasal 55). | Cite Pasal 55. |
| It takes seven attempts to leave. | No primary source. | Do not use. |
| Shelters are bad. | No evidence on conditions. | Shelters are scarce and uneven. Many areas have none. |
| Women stay because they cannot afford to leave. | Only 2.5% gave that reason for staying. | Money is a barrier to reporting. |
| SAPA always responds within a set time. | The standard sets times on paper only. Practice is not confirmed, and the Deputy Minister was asked about slow responses in June 2026. | On paper the standard sets response times. We do not know how fast it is in practice. |
| A conviction rate. A share of regions with a UPTD PPA. | Unverified or conflicting. | Leave out. |
| Telling her to leave, stay, or report. | Her pace and choice. | Information and a human hand-off. |
| A visum is usually free. DRAFT: based on AI research, not lawyer-reviewed. Team to approve. | No data supports "usually". The rule on paper (Permen PPPA 2/2022 Pasal 9(2)) says UPTD PPA services are not charged to her. But 2026 reports describe victims paying in several regions, and sources conflict on whether BPJS pays. Bekasi is not known. | On paper the service is not charged to her. Some victims have reported paying. We do not know about Bekasi. |
| There is no limit on how long she can stay in a shelter. Or: no rule on length of stay exists. | The national standard sets a maximum of 14 days in a UPTD PPA temporary shelter, then referral elsewhere based on assessment. DRAFT: based on AI research, not lawyer-reviewed. Team to approve. | Shelter in a UPTD PPA is temporary, up to 14 days, then referral elsewhere. We do not know if it is applied strictly or if Bekasi has a shelter. |
| These answers are lawyer-checked. | Lawyer review is still pending. | General information, not legal advice. |
