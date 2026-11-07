import SwiftUI

struct CoverNoteEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var note: CoverTask
    @State private var errorMessage: String?
    @State private var isSaving = false
    let onSave: (CoverTask) async throws -> Void

    init(note: CoverTask, onSave: @escaping (CoverTask) async throws -> Void) {
        var editable = note
        // Old cover tasks stay usable without rewriting the stored file on launch.
        if editable.checklist == nil, editable.body == nil, !editable.title.isEmpty {
            editable.checklist = [CoverChecklistItem(text: editable.title, isCompleted: editable.isCompleted)]
        }
        _note = State(initialValue: editable)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(note.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.system(size: 10)).foregroundStyle(CoverStyle.secondary)
                    TextField("Judul", text: $note.title, axis: .vertical)
                        .font(.custom("PlusJakartaSans-Regular", size: 28, relativeTo: .title).bold())
                        .autocorrectionDisabled().accessibilityIdentifier("cover.title")
                    Rectangle().fill(CoverStyle.border).frame(height: 1)
                    VStack(spacing: 4) {
                        ForEach(Array((note.checklist ?? []).enumerated()), id: \.element.id) { index, item in
                            HStack(alignment: .top, spacing: 14) {
                                Button {
                                    note.checklist?[index].isCompleted.toggle()
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.square" : "square")
                                        .font(.title2).foregroundStyle(CoverStyle.amber)
                                        .frame(minWidth: 30, minHeight: 44)
                                }
                                .accessibilityLabel(item.isCompleted ? "Tandai belum selesai" : "Tandai selesai")
                                TextField("Item", text: Binding(
                                    get: { note.checklist?[index].text ?? "" },
                                    set: { note.checklist?[index].text = $0 }
                                ), axis: .vertical)
                                    .frame(minHeight: 44)
                                    .foregroundStyle(item.isCompleted ? CoverStyle.secondary : EiraTheme.ink)

                            }
                            .contextMenu {
                                Button("Hapus item", role: .destructive) { note.checklist?.removeAll { $0.id == item.id } }
                            }
                        }
                    }
                    TextField("Tulis catatan…", text: Binding(
                        get: { note.body ?? "" }, set: { note.body = $0 }
                    ), axis: .vertical)
                        .lineLimit(8...20).accessibilityIdentifier("cover.body")
                    if let errorMessage { Text(errorMessage).foregroundStyle(CoverStyle.secondary) }
                }.padding(20)
            }
            .background(CoverStyle.background)
            .font(CoverStyle.body).foregroundStyle(EiraTheme.ink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Label("Catatan", systemImage: "chevron.left") }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") { save() }
                        .disabled(note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                        .accessibilityIdentifier("cover.save")
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        if note.checklist == nil { note.checklist = [] }
                        note.checklist?.append(CoverChecklistItem(text: ""))
                    } label: { Image(systemName: "checklist") }
                        .accessibilityLabel("Tambah item daftar")
                    Spacer()
                    Button {
                        note.isPinned = !(note.isPinned ?? false)
                    } label: { Image(systemName: note.isPinned == true ? "pin.fill" : "pin") }
                        .accessibilityLabel(note.isPinned == true ? "Lepas sematan" : "Sematkan")
                }
            }
            .tint(CoverStyle.amber)
            .interactiveDismissDisabled(isSaving)
        }
        .preferredColorScheme(.light)
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do { try await onSave(note); dismiss() }
            catch { errorMessage = "Catatan belum tersimpan. Coba lagi." }
        }
    }
}

#Preview {
    CoverNoteEditor(note: CoverTask(title: "Daftar belanja")) { _ in }
}
