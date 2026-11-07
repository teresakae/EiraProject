import SwiftUI

struct CoverScreen: View {
    let access: AccessFlow
    @State private var tasks: [CoverTask] = []
    @State private var title = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Tambah tugas", text: $title)
                            .autocorrectionDisabled().textInputAutocapitalization(.sentences)
                            .onSubmit { add() }.accessibilityIdentifier("cover.title")
                        Button("Tambah", systemImage: "plus") { add() }
                            .labelStyle(.iconOnly).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("cover.add")
                    }
                }
                Section {
                    ForEach(tasks) { task in
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    var updated = task
                                    updated.isCompleted.toggle()
                                    do { try access.store.saveCoverTask(updated); await load() }
                                    catch { errorMessage = "Perubahan belum tersimpan. Coba lagi." }
                                }
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(task.isCompleted ? "Tandai belum selesai" : "Tandai selesai")
                            Text(task.title).strikethrough(task.isCompleted)
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        }.padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { tasks[$0].id }
                        Task {
                            do { for id in ids { try access.store.deleteCoverTask(id: id) }; await load() }
                            catch { errorMessage = "Tugas belum bisa dihapus. Coba lagi." }
                        }
                    }
                    if tasks.isEmpty { Text("Belum ada tugas").foregroundStyle(.secondary) }
                }
                if let errorMessage { Text(errorMessage).font(.callout).foregroundStyle(.secondary) }
            }
            .navigationTitle("Eira")
            .task { await load() }
        }
    }

    private func add() {
        let value = title
        Task {
            do { try await access.addTask(value); title = ""; await load() }
            catch { errorMessage = "Tugas belum tersimpan. Coba lagi." }
        }
    }

    private func load() async {
        do { tasks = try access.store.coverTasks(); errorMessage = nil }
        catch { errorMessage = "Daftar tugas belum bisa dibuka. Coba lagi." }
    }
}

#Preview { CoverScreen(access: AccessFlow()) }
