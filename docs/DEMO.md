# Eira: 2-minute demo

Everything typed here is invented and in English, so the judges can read it. Sari is a design persona. The app's UI and AI replies are already English.

Tested 7 Nov 2026: all text below went through the server twice, and every quote passed the check. The screens have not been walked through or timed with it. Do one timed run.

## Before the demo

Someone on the team should read the 12 answers in `FAQ_APPROVED.md` and the confirmation copy in `SAFETY.md`. No person has read the FAQ text yet, and no lawyer has reviewed either.

### 1. Erase old data

In the app: new note titled `Eira`, Done, PIN `1111`, then Support, Delete everything. This removes entries, the report draft and the encryption key. It keeps cover notes, including old generated ones.

Then remove the app, which clears those notes too:

```bash
export EIRA_SIMULATOR_ID=CDEBB40E-648A-457A-8B41-C58E0DDE7100
```

```bash
xcrun simctl uninstall "$EIRA_SIMULATOR_ID" org.eira.app
```

### 2. Start the server and install

From the repository root. Stop any running server first, so it picks up the latest code.

```bash
cd server && npm start
```

In a second terminal, with `EIRA_SIMULATOR_ID` set as above:

```bash
xcodebuild -project Eira.xcodeproj -scheme Eira -configuration Debug -destination "platform=iOS Simulator,id=$EIRA_SIMULATOR_ID" -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- build
```

```bash
xcrun simctl install "$EIRA_SIMULATOR_ID" .build/DerivedData/Build/Products/Debug-iphonesimulator/Eira.app && xcrun simctl launch "$EIRA_SIMULATOR_ID" org.eira.app
```

Use a Debug simulator build. It forces the mock form. Never run a Release build from `main`.

### 3. Load the background entries

1. Add two ordinary notes: `Grocery list` and `Vegetable soup recipe`.
2. Open the private area: new note titled `Eira`, Done, PIN `1111`.
3. Home, Write in diary. Paste an entry, press Done, wait for it to return. Repeat for all six, in order.

They all show today's date, because the app stamps the phone's time.

```text
I'm 32 and live in Kota Bekasi, Jawa Barat with my husband, his parents and our two kids. I used to work at a fabric shop, but last year my husband made me quit. He said a wife doesn't need to work. Now I have to ask him before I buy anything.
```

```text
Almost every day he calls me stupid and says I can't run a house. When his mother is around he says it in front of her too. I'm scared of saying the wrong thing in my own home.
```

```text
Last month he gave me only 200,000 rupiah for the whole month's shopping, even though his pay hasn't changed. The kids and I mostly eat rice and eggs. When I ask, he says it's his business.
```

```text
Two months ago we were arguing about money and he slapped me once in the kitchen at home. The next day he said sorry and promised it wouldn't happen again. I didn't tell anyone.
```

```text
I'm not ready to tell anyone yet. My mother in Tegal only knows money is tight. What worries me most is the kids. I don't know who they would go with if I ever left.
```

```text
Writing this down in case I ever need it. All of this happened to me, not someone else. My name is Sari. I'm a woman. I don't have any disability. My phone number is 080000000001. If I ever report, I would report under my own name, Sari, and I don't want to be anonymous. I'm very worried.
```

With these six plus the paste entry, every report box fills from her words except two: Trusted adult's phone number, left empty on purpose for the "stays empty" line, and Type of disability, which doesn't apply. The phone number is made up, and only ever goes into the mock form.

### 4. Save a clean copy for practice

Save the app's data right after loading the six entries, and put it back between practice runs. That clears the chat, the paste entry, the report draft and any new cover notes, in seconds, with no re-pasting.

From the repository root, once, with the six entries loaded and nothing else done:

```bash
xcrun simctl terminate "$EIRA_SIMULATOR_ID" org.eira.app; rm -rf .build/demo-clean; cp -R "$(xcrun simctl get_app_container "$EIRA_SIMULATOR_ID" org.eira.app data)/Library/Application Support/Eira" .build/demo-clean
```

To reset after each practice run:

```bash
xcrun simctl terminate "$EIRA_SIMULATOR_ID" org.eira.app; D="$(xcrun simctl get_app_container "$EIRA_SIMULATOR_ID" org.eira.app data)/Library/Application Support/Eira"; rm -rf "$D" && cp -R .build/demo-clean "$D" && xcrun simctl launch "$EIRA_SIMULATOR_ID" org.eira.app
```

Rebuilding and reinstalling keeps the copy usable. Delete everything or uninstalling removes the encryption key, which makes the copy unreadable, so reload the six entries and save again.

### 5. Do a timed run, then reset

Run the script once and record it as a backup video (Ctrl-C to stop; don't commit the file):

```bash
xcrun simctl io "$EIRA_SIMULATOR_ID" recordVideo demo-backup.mov
```

The run adds an entry, a question and a report draft, so reset with the command in step 4. Then:

1. Delete any duplicate note titles on the cover. Titles are picked at random from 40, so a repeat is common.
2. Press Quick exit, so the app sits on Notes.
3. Copy the paste entry below onto the Mac clipboard.

## What you put in during the demo

**Paste entry** (Cmd+V):

```text
Last night around 11 my husband came home drunk and got angry because the rice wasn't ready. He slapped my left cheek twice, then shoved me and my head hit the wardrobe. My cheek is still swollen. The kids were in their room, but the older one (Dimas, 9) saw from the doorway. Last week he also told me I'm "useless, better off dead". This month he hasn't given me any shopping money at all.
```

Expect three events: Physical (swollen cheek, head hit the wardrobe, Dimas saw it), Psychological (the insult), Neglect (no shopping money).

**Legal question** (typed):

```text
If I report this, will my husband be arrested right away?
```

## The script

**0:00, Cover.** Show Notes. New note titled exactly `Eira`, Done, PIN `1111`.

> "In a 2024 national survey, 57.1% of Indonesian wives hit or sexually assaulted by a husband told no one. Eira is for women who aren't ready to report. To anyone glancing at her phone, it's a notes app. One note title and a PIN open the private space. Sari is an invented persona, and all this text is invented."

**0:25, Write.** Write in diary, Cmd+V, Done. Tap the new entry at the top of the list.

> "She writes once, in her own words. Eira pulls out three separate events: the violence, the insult, the money. Each one keeps her exact words. Plain code rejects any quote that isn't in her text."

**0:55, Ask.** Go back, press Talk it through. Ignore its first question and type the legal question.

> "She asks what she's actually afraid of: will he be arrested? For this question the answer is fixed text from our FAQ, not written by the AI, because getting it wrong could hurt her. It says what can happen and doesn't tell her what to do. No lawyer has reviewed this FAQ yet."

**1:20, Report.** Go back, then Support, Report draft. An empty draft fills itself: speak over the wait of about 8 seconds, then open the age field or the city field. On "stays empty", point at Trusted adult's phone number.

> "If she chooses, the report fills itself from what she's already said, using the real SAPA 129 form's fields. Every field shows the words it came from. Anything she never said stays empty. The form's own values stay in Indonesian, because the real form is."

**1:40, Send.** Review before sending, Open form to fill, Send to test form.

> "Eira fills the form but never sends it. She does. And this is a mock, so nothing reached SAPA. We're not claiming this keeps her safe. It helps her understand her options, at her own pace."

## If something goes wrong

| What happens | Do this |
|---|---|
| Running behind at 1:20 | Skip opening a field. Go straight to Review before sending |
| Eira asks another question instead of answering | The AI decides first whether this is a legal question. Type the legal question again. It's a fixed answer once it gets through |
| Another legal question says "cannot answer yet" | Only arrest questions are fixed. Say: "When the FAQ doesn't clearly cover it, Eira says so and points to a person." Move on |
| "Your entry is saved. Its reply or timeline could not be loaded." | Server or network is down. Check the server terminal, then play the backup video |
| What happened field is in Indonesian | Expected. The draft translates it for the real form, with her English words shown beside it. Don't open that field on stage |
| Conversation disappears | Pressing Home locks the app and clears it. Keep the simulator in front. Switching to another Mac app is fine |
| A practice question is in the way | In Debug builds, hold a question in Talk or a row in the diary, then tap Delete. This removes one record. To reset everything, use the command in step 4 |

Bring a phone hotspot, because the server needs to reach OpenAI.

## Words to avoid

| Do not say | Say instead |
|---|---|
| Keeps her safe, reduces violence | Helps her understand her options |
| The disguise can't be found | Lowers casual discovery only |
| Lawyer-checked | No lawyer has reviewed it yet |
| Nothing leaves the phone | Encrypted on the phone. To answer her, text goes through our server to OpenAI. Our server keeps no copy; OpenAI may keep it up to 30 days for abuse monitoring |
| He committed a crime, he could get X years | This could be a form of violence an article describes. Police and courts decide |
| Reporting gets him arrested | SAPA connects her to services. Staff may visit, and in high-risk cases may involve police |
| She should report | Success isn't whether she reports |

If a judge asks about real use: no user testing has been done yet, and KemenPPPA's agreement comes before anyone outside the team uses the real form.
