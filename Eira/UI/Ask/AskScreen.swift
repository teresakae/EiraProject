import SwiftUI

struct AskScreen: View {
    @State private var flow: AskFlow
    @State private var question = ""
    @State private var showsPrivacy = false

    init(dependencies: AppDependencies) {
        self.init(flow: AskFlow(dependencies: dependencies))
    }

    init(flow: AskFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if flow.turns.isEmpty {
                        Text("Kamu bisa bertanya tentang pilihanmu di sini.").foregroundStyle(.secondary)
                    }
                    ForEach(flow.turns) { turn in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(turn.entry.text)
                                .padding(12)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            if let response = turn.response {
                                Text(response.answer)
                                if AskFlow.needsLawyerCaveat(response) {
                                    Text(SafetyStrings.lawyerCaveat).font(.callout).foregroundStyle(.secondary)
                                        .accessibilityIdentifier("ask.lawyerCaveat")
                                }
                            } else if !flow.isWorking {
                                Button("Muat jawaban") { Task { await flow.retry(turn.entry) } }
                            }
                        }.id(turn.id)
                    }
                    if flow.isWorking { ProgressView("Memuat jawaban…") }
                    if let message = flow.errorMessage {
                        Text(message).font(.callout).foregroundStyle(.secondary)
                    }
                }.padding()
            }
            .onChange(of: flow.turns.count) {
                if let last = flow.turns.last { scroll.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .bottom) {
                TextField("Tulis pertanyaanmu", text: $question, axis: .vertical)
                    .lineLimit(1...6).textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled().textInputAutocapitalization(.sentences)
                    .disabled(flow.isWorking)
                Button("Kirim") {
                    let text = question
                    Task { if await flow.send(text) { question = "" } }
                }
                .disabled(flow.isWorking || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.padding().background(.bar)
        }
        .navigationTitle("Tanya")
        .toolbar { Button(SafetyStrings.privacyTitle, systemImage: "info.circle") { showsPrivacy = true } }
        .task { await flow.load() }
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
    }
}

struct PrivacyCopyScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView { Text(SafetyStrings.privacy).padding().frame(maxWidth: .infinity, alignment: .leading) }
                .navigationTitle(SafetyStrings.privacyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Tutup") { dismiss() } }
        }
    }
}

#Preview { NavigationStack { AskScreen(dependencies: AppDependencies()) } }
