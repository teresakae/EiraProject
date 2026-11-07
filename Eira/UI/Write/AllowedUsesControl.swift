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
                        Toggle("Personal timeline", isOn: binding(\.personalTimeline))
                    }
                    Toggle("Legal guidance", isOn: binding(\.legalGuidance))
                    Toggle("Report", isOn: binding(\.report))
                    if entry.kind == .story {
                        Text("Changing these choices does not delete your entry. New entries are still sent to build your timeline.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.disabled(isSaving)
                .navigationTitle("Entry uses")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { showsSheet = false } }
            }.presentationDetents([.medium])
        }
    }

    private var current: AllowedUses { entry.allowedUses }
    private var summary: String {
        let uses = [(entry.kind == .story && current.personalTimeline, "timeline"),
                    (current.legalGuidance, "legal guidance"), (current.report, "report")]
            .filter(\.0).map(\.1)
        return uses.isEmpty ? "Not used elsewhere · Change" : "Used for \(uses.joined(separator: ", ")) · Change"
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
