import SwiftUI

struct AskScreen: View {
    @State private var flow: AskFlow
    @Bindable private var voice: VoiceFlow
    private let onSummary: () -> Void
    private let onExit: (() -> Void)?
    @State private var message = ""
    @State private var messageSource = EntrySource.text
    @State private var isHoldingMic = false
    @State private var showsPrivacy = false
    @FocusState private var isTyping: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(dependencies: AppDependencies, voice: VoiceFlow? = nil,
         onSummary: @escaping () -> Void = {}, onExit: (() -> Void)? = nil) {
        self.init(flow: AskFlow(dependencies: dependencies),
                  voice: voice ?? VoiceFlow(client: dependencies.serverClient),
                  onSummary: onSummary, onExit: onExit)
    }

    init(flow: AskFlow, voice: VoiceFlow = VoiceFlow(client: CannedServerClient()),
         onSummary: @escaping () -> Void = {}, onExit: (() -> Void)? = nil) {
        _flow = State(initialValue: flow)
        self.voice = voice
        self.onSummary = onSummary
        self.onExit = onExit
    }

    private var arrival: Animation { reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.25) }
    private var messageArrival: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8))
    }
    private var bottomVersion: Int {
        flow.turns.count + flow.prompts.count + flow.quickReplies.count + flow.turns.filter { $0.response != nil }.count
            + (flow.isWorking ? 1 : 0)
    }

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(SafetyStrings.talkOpening(entryDate: flow.latestStoryDate))
                        .font(EiraTheme.story).foregroundStyle(EiraTheme.ink)
                        .frame(maxWidth: 300, alignment: .leading)
                    ForEach(flow.prompts(after: nil)) { prompt($0) }
                    ForEach(flow.turns) { turn in
                        turnView(turn).transition(messageArrival)
                        ForEach(flow.prompts(after: turn.id)) { prompt($0) }
                    }
                    if flow.isWorking {
                        TypingDots().transition(.opacity)
                    } else if flow.hasOpenQuestion {
                        quickReplies.transition(.opacity)
                    }
                    if let error = flow.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).font(.callout).foregroundStyle(.secondary)
                            if let last = flow.turns.last, last.response == nil, last.entry.allowedUses.legalGuidance {
                                Button("Try again") { Task { await flow.retry(last.entry) } }
                                    .font(EiraTheme.body).underline().foregroundStyle(EiraTheme.sage)
                            }
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
                .animation(arrival, value: bottomVersion)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: bottomVersion) { scroll.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: isTyping) { if isTyping { scroll.scrollTo("bottom", anchor: .bottom) } }
            .safeAreaInset(edge: .top, spacing: 0) {
                if flow.hasNotedFacts { notedBanner.transition(.opacity) }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .animation(arrival, value: flow.hasNotedFacts)
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "TALK IT THROUGH") }
            if let onExit { ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) } }
        }
        .task { await flow.start() }
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .onDisappear { voice.cancel() }
        .sensoryFeedback(.impact(weight: .light), trigger: voice.isRecording)
    }

    private func prompt(_ prompt: AskFlow.Prompt) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if prompt.skipped {
                Text("Skipped").font(EiraTheme.micro).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            RevealText(text: prompt.text, animate: prompt.id == flow.latestReplyID)
        }.transition(messageArrival)
    }

    private func turnView(_ turn: AskFlow.Turn) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(turn.entry.text)
                    .font(EiraTheme.story).foregroundStyle(EiraTheme.ink)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(EiraTheme.sageTint) }
                    .debugHoldToDelete { Task { await flow.deleteQuestion(turn.id) } }
                AllowedUsesControl(entry: turn.entry) { uses in
                    await flow.setUses(uses, for: turn.id)
                }
            }
            .padding(.leading, 48)
            .frame(maxWidth: .infinity, alignment: .trailing)

            let noted = flow.noted(for: turn.id)
            if !noted.isEmpty { NotedCard(facts: noted, animate: turn.id == flow.latestReplyID, action: onSummary) }

            if let response = turn.response {
                RevealText(text: response.answer, animate: turn.id == flow.latestReplyID)
                    .transition(messageArrival)
                if AskFlow.needsLawyerCaveat(response) {
                    Text(SafetyStrings.lawyerCaveat).font(.callout).foregroundStyle(.secondary)
                        .accessibilityIdentifier("ask.lawyerCaveat")
                }
            }
        }.id(turn.id)
    }

    private var notedBanner: some View {
        Button(action: onSummary) {
            HStack {
                Text("What Eira noted").font(EiraTheme.body.weight(.semibold))
                Spacer()
                Text("View ›").font(EiraTheme.body.weight(.semibold))
            }
            .foregroundStyle(EiraTheme.sage)
            .padding(.horizontal, 16).frame(minHeight: 48)
            .background(EiraTheme.sageTint, in: RoundedRectangle(cornerRadius: 12))
            .phaseAnimator([1.0, 1.02, 1.0], trigger: reduceMotion ? 0 : flow.notedFactCount) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in .easeInOut(duration: 0.18) }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(EiraTheme.paper)
        .accessibilityIdentifier("talk.noted")
    }

    private var quickReplies: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { quickReplyChips }
            VStack(alignment: .leading, spacing: 8) { quickReplyChips }
        }
    }

    @ViewBuilder private var quickReplyChips: some View {
        ForEach(Array(flow.quickReplies.enumerated()), id: \.element) { index, reply in
            QuickReplyChip(title: reply, delay: Double(index) * 0.05) {
                Task { _ = await flow.sendQuickReply(reply) }
            }
        }
        QuickReplyChip(title: "Skip", delay: Double(flow.quickReplies.count) * 0.05) {
            Task { await flow.skip() }
        }.accessibilityIdentifier("talk.skip")
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if voice.isWorking { Text("Transcribing audio…").font(EiraTheme.micro).foregroundStyle(.secondary) }
            if voice.isRecording { Text("Recording… Let go to finish.").font(EiraTheme.micro).foregroundStyle(EiraTheme.sage) }
            if let error = voice.errorMessage { Text(error).font(EiraTheme.micro).foregroundStyle(.secondary) }
            if !isTyping && !voice.isRecording {
                Button(SafetyStrings.privacyTitle) { showsPrivacy = true }
                    .font(EiraTheme.micro).underline().foregroundStyle(EiraTheme.sage)
                    .frame(minHeight: 28)
            }
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Type, or hold the mic to speak", text: $message, axis: .vertical)
                    .font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                    .lineLimit(1...5)
                    .focused($isTyping)
                    .textInputAutocapitalization(.sentences).autocorrectionDisabled()
                    .disabled(flow.isWorking || voice.isRecording || voice.isWorking)
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                    .overlay { RoundedRectangle(cornerRadius: 24).stroke(EiraTheme.sageTint) }
                    .accessibilityIdentifier("talk.input")
                if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    micButton.transition(.opacity)
                } else {
                    sendButton.transition(.opacity)
                }
            }
            .animation(arrival, value: message.isEmpty)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
        .background(EiraTheme.paper)
    }

    private var sendButton: some View {
        Button {
            let text = message
            let source = messageSource
            Task {
                if await flow.send(text, source: source) { message = ""; messageSource = .text }
            }
        } label: {
            Image(systemName: "arrow.up").font(.system(size: 18, weight: .semibold))
                .foregroundStyle(EiraTheme.paper)
                .frame(width: 50, height: 50).background(EiraTheme.sage, in: Circle())
        }
        .disabled(flow.isWorking)
        .accessibilityLabel("Send")
        .accessibilityIdentifier("talk.send")
    }

    private var micButton: some View {
        Image(systemName: "mic")
            .font(.system(size: 18))
            .foregroundStyle(voice.isRecording ? EiraTheme.paper : EiraTheme.sage)
            .frame(width: 50, height: 50)
            .background(voice.isRecording ? EiraTheme.sage : EiraTheme.surface, in: Circle())
            .overlay { Circle().stroke(EiraTheme.sageTint) }
            .background { if voice.isRecording && !reduceMotion { MicPulse() } }
            .scaleEffect(voice.isRecording && !reduceMotion ? 1.12 : 1)
            .animation(.easeOut(duration: 0.18), value: voice.isRecording)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHoldingMic else { return }
                    isHoldingMic = true
                    isTyping = false
                    voice.start()
                }
                .onEnded { _ in
                    isHoldingMic = false
                    finishRecording()
                })
            .opacity(flow.isWorking || voice.isWorking ? 0.45 : 1)
            .allowsHitTesting(!flow.isWorking && !voice.isWorking)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(voice.isRecording ? "Stop recording" : "Record your answer")
            .accessibilityAction {
                if voice.isRecording { finishRecording() } else { voice.start() }
            }
    }

    private func finishRecording() {
        // A release before recording starts (for example at the permission prompt) cancels it.
        guard voice.isRecording else { voice.cancel(); return }
        voice.finish { transcript in
            message += (message.isEmpty ? "" : "\n") + transcript
            messageSource = .voice
        }
    }
}

// Words fade in once; the full text is laid out from the start, so nothing jumps and VoiceOver reads it all.
private struct RevealText: View {
    let text: String
    let animate: Bool
    @State private var start = Date()
    @State private var finished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let wordGap = 0.03
    private let wordFade = 0.18
    private var duration: Double { Double(text.split(separator: " ").count) * wordGap + wordFade }

    var body: some View {
        Group {
            if animate && !reduceMotion && !finished {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    Text(revealed(at: context.date.timeIntervalSince(start)))
                }
                .task {
                    try? await Task.sleep(for: .seconds(duration))
                    finished = true
                }
            } else {
                Text(text)
            }
        }
        .font(EiraTheme.story).foregroundStyle(EiraTheme.ink)
        .frame(maxWidth: 300, alignment: .leading)
    }

    private func revealed(at elapsed: Double) -> AttributedString {
        var output = AttributedString()
        var index = 0
        for piece in text.split(separator: " ", omittingEmptySubsequences: false) {
            var word = AttributedString(piece + " ")
            let progress = min(1, max(0, (elapsed - Double(index) * wordGap) / wordFade))
            word.foregroundColor = EiraTheme.ink.opacity(progress)
            output += word
            index += 1
        }
        return output
    }
}

// Shown after a short wait, so a fast reply does not flicker the dots.
private struct TypingDots: View {
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 5) {
            if isVisible {
                if reduceMotion {
                    ForEach(0..<3, id: \.self) { _ in dot.opacity(0.6) }
                } else {
                    PhaseAnimator([0, 1, 2]) { phase in
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { index in dot.opacity(phase == index ? 1 : 0.3) }
                        }
                    } animation: { _ in .easeInOut(duration: 0.35) }
                }
            }
        }
        .frame(height: 24, alignment: .leading)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isVisible = true
        }
        .accessibilityElement()
        .accessibilityLabel("Eira is writing")
    }

    private var dot: some View { Circle().fill(EiraTheme.sage).frame(width: 7, height: 7) }
}

private struct MicPulse: View {
    var body: some View {
        PhaseAnimator([false, true]) { expanded in
            Circle().stroke(EiraTheme.sage, lineWidth: 2)
                .scaleEffect(expanded ? 1.35 : 1)
                .opacity(expanded ? 0 : 0.5)
        } animation: { expanded in expanded ? .easeOut(duration: 0.9) : .linear(duration: 0.01) }
    }
}

private struct QuickReplyChip: View {
    let title: String
    let delay: Double
    let action: () -> Void
    @State private var isShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title).font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 18).frame(minHeight: 44)
                .background(EiraTheme.surface, in: Capsule())
                .overlay { Capsule().stroke(EiraTheme.sage.opacity(0.4)) }
        }
        .buttonStyle(.plain)
        .opacity(isShown ? 1 : 0)
        .offset(y: isShown || reduceMotion ? 0 : 6)
        .animation(.easeOut(duration: 0.2).delay(reduceMotion ? 0 : delay), value: isShown)
        .onAppear { isShown = true }
    }
}

private struct NotedCard: View {
    let facts: [TalkFact]
    let animate: Bool
    let action: () -> Void
    @State private var isDrawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var summary: String {
        facts.map { "\(SafetyStrings.factLabel($0.category)): \($0.value)" }.joined(separator: " · ")
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTED · TAP TO FIX").font(EiraTheme.micro.weight(.semibold)).tracking(1).foregroundStyle(EiraTheme.sage)
                Text(summary).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .opacity(isDrawn ? 1 : 0)
                    .animation(.easeOut(duration: 0.2).delay(reduceMotion ? 0 : 0.2), value: isDrawn)
            }
            .padding(14)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .trim(from: 0, to: isDrawn || reduceMotion ? 1 : 0)
                    .stroke(EiraTheme.sage, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .animation(.easeOut(duration: 0.35), value: isDrawn)
            }
        }
        .buttonStyle(.plain)
        .onAppear { isDrawn = true }
        .transaction { if !animate { $0.animation = nil } }
        .accessibilityLabel("Noted. \(summary). Tap to fix.")
    }
}

struct EiraScreenTitle: View {
    let text: String
    var body: some View {
        Text(text).font(EiraTheme.micro.weight(.medium)).tracking(1.4).foregroundStyle(EiraTheme.sage)
    }
}

struct QuickExitButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                Text("Quick exit").font(EiraTheme.body.weight(.semibold)).fixedSize()
            }
            .foregroundStyle(EiraTheme.paper)
            .padding(.horizontal, 14).frame(minHeight: 36)
            .background(EiraTheme.sage, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("private.quickExit")
    }
}

struct PrivacyCopyScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView { Text(SafetyStrings.privacy).padding().frame(maxWidth: .infinity, alignment: .leading) }
                .navigationTitle(SafetyStrings.privacyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Close") { dismiss() } }
        }
    }
}

#Preview { NavigationStack { AskScreen(dependencies: AppDependencies(), onExit: {}) } }
