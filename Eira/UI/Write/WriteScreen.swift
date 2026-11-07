import SwiftUI

struct WriteScreen: View {
    @Bindable var flow: WriteFlow
    @Bindable var voice: VoiceFlow
    @State private var showsPrivacy = false
    @FocusState private var isWriting: Bool
    @State private var draftStartedAt = Date()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                composer
                if !flow.entries.isEmpty {
                    Text("Catatanmu").font(EiraTheme.title).foregroundStyle(EiraTheme.sage)
                }
                ForEach(flow.entries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                        Text(entry.text).padding(12)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .contextMenu { Button("Hapus catatan", role: .destructive) { Task { await flow.deleteEntry(entry.id) } } }
                        AllowedUsesControl(entry: entry) { uses in await flow.setUses(uses, for: entry.id) }
                        if let reply = entry.writeReply { Text(reply) }
                    }
                }
                if !flow.timeline.isEmpty {
                    Text("Linimasa").font(.title2.bold()).padding(.top)
                    ForEach(flow.timeline) { event in
                        VStack(alignment: .leading, spacing: 8) {
                            if let entry = flow.entries.first(where: { $0.id == event.entryID }) {
                                Text(entry.createdAt, format: .dateTime.day().month().year())
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let when = event.whenText { Text(when).font(.subheadline) }
                            Text(event.whatHappened)
                            Text("“\(event.quote)”").font(.callout).foregroundStyle(.secondary)
                            if let injuries = event.injuries { Text("Luka: \(injuries)").font(.callout) }
                            if !event.witnesses.isEmpty { Text("Saksi: \(event.witnesses.joined(separator: ", "))").font(.callout) }
                            Picker(event.userEdited ? "Jenis · Diubah olehmu" : "Jenis · Saran", selection: Binding(
                                get: { event.violenceType },
                                set: { type in Task { await flow.setType(type, for: event.id) } }
                            )) {
                                ForEach([ViolenceType.physical, .psychological, .sexual, .neglect, .unsure], id: \.self) {
                                    Text(label($0)).tag($0)
                                }
                            }
                        }.padding().background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                if flow.isWorking { ProgressView("Memuat balasan…") }
                if let message = flow.errorMessage { Text(message).font(.callout).foregroundStyle(.secondary) }
                if let message = voice.errorMessage { Text(message).font(.callout).foregroundStyle(.secondary) }
            }.padding()
        }
        .background(EiraTheme.paper)
        .font(EiraTheme.body)
        .foregroundStyle(EiraTheme.ink)
        .tint(EiraTheme.sage)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .task { await flow.load() }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(draftStartedAt, format: .dateTime.day().month(.wide).hour().minute())
                    .font(EiraTheme.micro)
                Text("Catatan baru").font(EiraTheme.title)
            }
            .foregroundStyle(EiraTheme.sage)
            .padding(.horizontal, 4)

            ZStack(alignment: .topLeading) {
                if flow.text.isEmpty {
                    Text("Ceritakan apa yang ingin kamu catat…")
                        .padding(.horizontal, 5).padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $flow.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 260)
                    .focused($isWriting)
                    .disabled(flow.isWorking || voice.isWorking || voice.isRecording)
                    .accessibilityLabel("Tulis catatanmu")
                    .accessibilityIdentifier("write.input")
            }
            .font(EiraTheme.story)
            .foregroundStyle(EiraTheme.sage)
            .padding(16)
            .background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }

            Button(SafetyStrings.privacyTitle) { showsPrivacy = true }
                .foregroundStyle(EiraTheme.sage)
                .font(EiraTheme.body)
                .frame(minHeight: 44, alignment: .leading)
        }
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(EiraTheme.sageTint).frame(height: 1)
            if voice.isWorking {
                ProgressView("Mengubah suara menjadi teks…").padding(.top, 12)
            }
            HStack(spacing: 12) {
                Button {
                    isWriting = false
                    if voice.isRecording { voice.finish(into: flow) } else { voice.start() }
                } label: {
                    Text(voice.isRecording ? "Selesai merekam" : "Rekam cerita")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .disabled(voice.isWorking || flow.isWorking)

                Button {
                    isWriting = false
                    flow.submit()
                    draftStartedAt = Date()
                } label: {
                    Text("Simpan").frame(maxWidth: .infinity, minHeight: 52)
                }
                .disabled(flow.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || flow.isWorking || voice.isRecording || voice.isWorking)
                .accessibilityIdentifier("write.send")
            }
            .font(EiraTheme.action)
            .buttonStyle(DiaryActionStyle())
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
        .background(EiraTheme.paper)
    }

    private func label(_ type: ViolenceType) -> String {
        switch type {
        case .physical: "Fisik"
        case .psychological: "Psikis"
        case .sexual: "Seksual"
        case .neglect: "Penelantaran"
        case .unsure: "Tidak yakin"
        }
    }
}

#Preview {
    let dependencies = AppDependencies()
    NavigationStack { WriteScreen(flow: WriteFlow(dependencies: dependencies), voice: VoiceFlow(client: dependencies.serverClient)) }
}

private struct DiaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(EiraTheme.sage)
            .background(configuration.isPressed ? EiraTheme.sageTint : EiraTheme.surface, in: Capsule())
            .overlay { Capsule().stroke(EiraTheme.sageTint) }
            .opacity(isEnabled ? 1 : 0.45)
    }
}
