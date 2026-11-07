import SwiftUI

struct WriteScreen: View {
    @Bindable var flow: WriteFlow
    @Bindable var voice: VoiceFlow
    @State private var showsPrivacy = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if flow.entries.isEmpty { Text("Tulis apa yang ingin kamu catat.").foregroundStyle(.secondary) }
                ForEach(flow.entries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                        Text(entry.text).padding(12)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .contextMenu { Button("Hapus catatan", role: .destructive) { Task { await flow.deleteEntry(entry.id) } } }
                        AllowedUsesControl(entry: entry, flow: flow)
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
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .bottom) {
                Button {
                    if voice.isRecording { voice.finish(into: flow) } else { voice.start() }
                } label: { Image(systemName: voice.isRecording ? "stop.circle.fill" : "mic") }
                    .accessibilityLabel(voice.isRecording ? "Selesai merekam" : "Rekam suara")
                    .disabled(voice.isWorking || flow.isWorking)
                TextField("Tulis catatanmu", text: $flow.text, axis: .vertical)
                    .lineLimit(1...6).textFieldStyle(.roundedBorder).autocorrectionDisabled()
                    .disabled(flow.isWorking || voice.isWorking || voice.isRecording)
                    .accessibilityIdentifier("write.input")
                Button("Kirim") { flow.submit() }
                    .disabled(flow.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || flow.isWorking || voice.isRecording || voice.isWorking)
                    .accessibilityIdentifier("write.send")
            }.padding().background(.bar)
        }
        .navigationTitle("Tulis")
        .toolbar { Button(SafetyStrings.privacyTitle, systemImage: "info.circle") { showsPrivacy = true } }
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .task { await flow.load() }
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
