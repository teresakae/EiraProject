import SwiftUI

struct AllowedUsesControl: View {
    let entry: Entry
    let onChange: (AllowedUses) async -> Void
    @State private var showsSheet = false
    @State private var isSaving = false

    var body: some View {
        Button {
            showsSheet = true
        } label: {
            Text(summary).font(.caption).foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showsSheet) {
            NavigationStack {
                Form {
                    if entry.kind == .story {
                        Toggle("Linimasa pribadi", isOn: binding(\.personalTimeline))
                    }
                    Toggle("Panduan hukum", isOn: binding(\.legalGuidance))
                    Toggle("Laporan", isOn: binding(\.report))
                    if entry.kind == .story {
                        Text("Mengubah pilihan ini tidak menghapus catatanmu. Catatan baru tetap dikirim untuk menyusun linimasa.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.disabled(isSaving)
                .navigationTitle("Penggunaan catatan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Selesai") { showsSheet = false } }
            }.presentationDetents([.medium])
        }
    }

    private var current: AllowedUses { entry.allowedUses }
    private var summary: String {
        let uses = [(entry.kind == .story && current.personalTimeline, "linimasa"),
                    (current.legalGuidance, "panduan hukum"), (current.report, "laporan")]
            .filter(\.0).map(\.1)
        return uses.isEmpty ? "Tidak digunakan di tahap lain · Ubah" : "Digunakan untuk \(uses.joined(separator: ", ")) · Ubah"
    }

    private func binding(_ path: WritableKeyPath<AllowedUses, Bool>) -> Binding<Bool> {
        Binding(get: { current[keyPath: path] }, set: { value in
            var uses = current
            uses[keyPath: path] = value
            isSaving = true
            Task {
                await onChange(uses)
                isSaving = false
            }
        })
    }
}
