import SwiftUI

struct WriteScreen: View {
    @Bindable var flow: WriteFlow
    @Bindable var voice: VoiceFlow
    var onDone: (() -> Void)? = nil
    var onTalk: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrivacy = false
    @State private var activePrompt: WritingPrompt?
    @State private var operation: Task<Void, Never>?
    @FocusState private var isWriting: Bool
    @State private var draftStartedAt = Date()
    @ScaledMetric(relativeTo: .body) private var cardHeight = 300

    private let canvas = Color(white: 247.0 / 255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(draftStartedAt, format: .dateTime.day().month(.wide))
                        Text("·").foregroundStyle(EiraTheme.sageTint)
                        Text(draftStartedAt, format: .dateTime.hour().minute())
                    }.font(EiraTheme.micro)
                    Text("New Chat").font(EiraTheme.title)
                }
                .foregroundStyle(EiraTheme.sage)
                .padding(.horizontal, 4).padding(.top, 20).padding(.bottom, 16)

                ZStack(alignment: .topLeading) {
                    if flow.text.isEmpty {
                        Text("Tell your stories")
                            .padding(.horizontal, 5).padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $flow.text)
                        .scrollContentBackground(.hidden)
                        .focused($isWriting)
                        .disabled(flow.isWorking || voice.isWorking || voice.isRecording)
                        .accessibilityLabel("Write your story")
                        .accessibilityIdentifier("write.input")
                }
                .font(EiraTheme.story).foregroundStyle(EiraTheme.sage)
                .padding(16).frame(height: cardHeight)
                .background(Color(red: 250.0 / 255, green: 250.0 / 255, blue: 248.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        isWriting = false
                        if voice.isRecording { voice.finish(into: flow) } else { voice.start() }
                    } label: {
                        Image(systemName: voice.isRecording ? "stop.circle" : "mic")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(voice.isRecording ? "Stop recording" : "Record story")
                    .disabled(flow.isWorking || voice.isWorking)
                    .padding(4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("If you want, these details help a report later")
                        .font(.custom("EiraFraunces-Regular", size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color(white: 0.35)).padding(.bottom, 2)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { promptChip(.who); promptChip(.whereAt); promptChip(.what) }
                        VStack(alignment: .leading, spacing: 8) { promptChip(.who); promptChip(.whereAt); promptChip(.what) }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { promptChip(.witnesses); promptChip(.after) }
                        VStack(alignment: .leading, spacing: 8) { promptChip(.witnesses); promptChip(.after) }
                    }
                    promptChip(.photo)
                }.padding(.top, 20)

                if flow.isWorking { ProgressView("Saving your entry…").padding(.top, 16) }
                if voice.isWorking { ProgressView("Transcribing audio…").padding(.top, 16) }
                if voice.isRecording { Text("Recording… Tap the microphone to finish.").padding(.top, 16) }
                if let message = flow.errorMessage ?? voice.errorMessage {
                    Text(message).font(.callout).foregroundStyle(.secondary).padding(.top, 16)
                }
            }.padding(.horizontal, 20).padding(.bottom, 20)
        }
        .background(canvas)
        .font(EiraTheme.body).tint(EiraTheme.sage)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .alert(item: $activePrompt) { prompt in
            Alert(title: Text(prompt.title), message: Text(prompt.question), dismissButton: .default(Text("Keep writing")) { isWriting = true })
        }
        .task { await flow.load() }
        .onDisappear { operation?.cancel(); voice.cancel() }
    }

    private func promptChip(_ prompt: WritingPrompt) -> some View {
        Button { isWriting = false; activePrompt = prompt } label: {
            HStack(spacing: 6) {
                Image(systemName: prompt.isPrimary ? "checkmark" : "plus").font(.system(size: 12, weight: .semibold))
                Text(prompt.title).font(EiraTheme.body).fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(prompt.isPrimary ? EiraTheme.sage : Color(white: 0.35))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(prompt.isPrimary ? EiraTheme.sageTint : canvas, in: Capsule())
            .overlay { Capsule().stroke(prompt.isPrimary ? Color(red: 168.0 / 255, green: 186.0 / 255, blue: 156.0 / 255) : Color(white: 217.0 / 255)) }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(prompt.title), writing prompt")
        .accessibilityIdentifier("write.prompt.\(prompt.rawValue)")
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            Button { showsPrivacy = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock").font(.system(size: 14))
                        .frame(width: 28, height: 28).background(EiraTheme.sageTint, in: RoundedRectangle(cornerRadius: 6))
                    Text(SafetyStrings.privacyTitle).font(EiraTheme.body)
                }
                .foregroundStyle(EiraTheme.sage)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 20).padding(.vertical, 4)
            }.buttonStyle(.plain)
            Rectangle().fill(EiraTheme.sageTint).frame(height: 1)
            HStack(spacing: 12) {
                Button("Talk it through") { save(andTalk: true) }
                    .frame(maxWidth: .infinity)
                    .disabled(flow.isWorking || voice.isWorking || voice.isRecording || onTalk == nil)
                    .accessibilityHint("Saves your entry and opens Talk it through")
                    .accessibilityIdentifier("write.talk")
                Button("Done") { save(andTalk: false) }
                    .frame(maxWidth: .infinity)
                    .disabled(flow.isWorking || voice.isWorking || voice.isRecording)
                    .accessibilityIdentifier("write.send")
            }
            .font(EiraTheme.action).buttonStyle(DiaryActionStyle())
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
        }.background(canvas)
    }

    private func save(andTalk: Bool) {
        isWriting = false
        let text = flow.text
        let source = flow.source
        operation = Task {
            let saved = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? true : await flow.send(text, source: source)
            guard saved, !Task.isCancelled else { return }
            if andTalk { onTalk?() }
            else if let onDone { onDone() }
            else { dismiss() }
        }
    }
}

// Checkmarks distinguish the three primary topics in the design; they are not completeness assessments.
private enum WritingPrompt: String, Identifiable {
    case who, whereAt, what, witnesses, after, photo
    var id: String { rawValue }
    var isPrimary: Bool { [.who, .whereAt, .what].contains(self) }
    var title: String {
        switch self {
        case .who: "Who"
        case .whereAt: "Where"
        case .what: "What they did"
        case .witnesses: "Anyone who saw or heard"
        case .after: "What you did after"
        case .photo: "Photo or screenshot"
        }
    }
    var question: String {
        switch self {
        case .who: "Who was involved? Write only what you want to include."
        case .whereAt: "Where did it happen? Include only what you remember."
        case .what: "What did they say or do? You can use your own words."
        case .witnesses: "Did anyone see or hear what happened? You can describe what they noticed."
        case .after: "What did you do afterwards, if anything?"
        case .photo: "If a photo or screenshot matters to your story, you can describe what it shows. This entry supports text only."
        }
    }
}

#Preview {
    let dependencies = AppDependencies()
    NavigationStack { WriteScreen(flow: WriteFlow(dependencies: dependencies), voice: VoiceFlow(client: dependencies.serverClient), onTalk: {}) }
}

private struct DiaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(EiraTheme.sage)
            .background(configuration.isPressed ? EiraTheme.sageTint : Color(white: 247.0 / 255), in: Capsule())
            .overlay { Capsule().stroke(EiraTheme.sageTint) }
            .opacity(isEnabled ? 1 : 0.45)
    }
}
