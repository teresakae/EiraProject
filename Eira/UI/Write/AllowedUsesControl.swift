import SwiftUI

struct AllowedUsesControl: View {
    let entry: Entry
    let flow: WriteFlow
    @State private var showsSheet = false

    var body: some View {
        Button {
            showsSheet = true
        } label: {
            Text(summary).font(.caption).foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showsSheet) {
            NavigationStack {
                Form {
                    Toggle("Linimasa pribadi", isOn: binding(\.personalTimeline))
                    Toggle("Panduan hukum", isOn: binding(\.legalGuidance))
                    Toggle("Laporan", isOn: binding(\.report))
                    Text("Mengubah pilihan ini tidak menghapus catatanmu. Catatan baru tetap dikirim untuk menyusun linimasa.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .navigationTitle("Penggunaan catatan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Selesai") { showsSheet = false } }
            }.presentationDetents([.medium])
        }
    }

    private var current: AllowedUses { flow.entries.first(where: { $0.id == entry.id })?.allowedUses ?? entry.allowedUses }
    private var summary: String {
        let uses = [(current.personalTimeline, "linimasa"), (current.legalGuidance, "panduan hukum"), (current.report, "laporan")]
            .filter(\.0).map(\.1)
        return uses.isEmpty ? "Tidak digunakan di tahap lain · Ubah" : "Digunakan untuk \(uses.joined(separator: ", ")) · Ubah"
    }

    private func binding(_ path: WritableKeyPath<AllowedUses, Bool>) -> Binding<Bool> {
        Binding(get: { current[keyPath: path] }, set: { value in
            var uses = current
            uses[keyPath: path] = value
            Task { await flow.setUses(uses, for: entry.id) }
        })
    }
}
