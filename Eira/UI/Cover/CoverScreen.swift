import SwiftUI

struct CoverScreen: View {
    let access: AccessFlow
    @State private var notes: [CoverTask] = []
    @State private var search = ""
    @State private var editing: CoverTask?
    @State private var errorMessage: String?

    private var filtered: [CoverTask] {
        notes.filter { search.isEmpty || ($0.title + " " + ($0.body ?? "") + " " + ($0.checklist ?? []).map(\.text).joined(separator: " ")).localizedCaseInsensitiveContains(search) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").font(.custom("PlusJakartaSans-Regular", size: 32, relativeTo: .largeTitle).bold())
                        Text("\(notes.count) notes").font(.caption).foregroundStyle(CoverStyle.secondary)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(CoverStyle.secondary)
                        TextField("Search notes…", text: $search)
                            .accessibilityIdentifier("cover.search")
                    }
                    .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(CoverStyle.border) }
                    noteSection("Pinned", pinned: true)
                    noteSection("Recent", pinned: false)
                    if notes.isEmpty {
                        Text("No notes yet").foregroundStyle(CoverStyle.secondary).padding(.vertical, 24)
                    } else if filtered.isEmpty {
                        Text("No notes found").foregroundStyle(CoverStyle.secondary)
                    }
                    if let message = errorMessage ?? (access.gate == nil && !access.isInactive ? access.errorMessage : nil) {
                        Text(message).foregroundStyle(CoverStyle.secondary)
                    }
                }.padding(20)
            }
            .background(CoverStyle.background)
            .font(CoverStyle.body)
            .foregroundStyle(EiraTheme.ink)
            .tint(CoverStyle.amber)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Text("\(notes.count) notes").font(.caption).foregroundStyle(CoverStyle.secondary)
                    Spacer()
                    Button { editing = CoverTask(title: "") } label: {
                        Image(systemName: "square.and.pencil").font(.title3)
                            .frame(width: 52, height: 52)
                            .foregroundStyle(.white)
                            .background(CoverStyle.amber, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .accessibilityLabel("New note").accessibilityIdentifier("cover.add")
                }.padding(.horizontal, 20).padding(.vertical, 10).background(.white)
                    .overlay(alignment: .top) { Rectangle().fill(CoverStyle.border).frame(height: 1) }
            }
            .sheet(item: $editing, onDismiss: { Task { await load() } }) { note in
                CoverNoteEditor(note: note) { updated in
                    if updated.title == "Eira" {
                        try await access.addTask(updated.title)
                    } else {
                        try access.store.saveCoverTask(updated)
                    }
                }
            }
            .task { await load() }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder private func noteSection(_ heading: String, pinned: Bool) -> some View {
        let group = filtered.filter { ($0.isPinned ?? false) == pinned }
        if !group.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(heading).font(.headline)
                ForEach(group) { note in
                    Button { editing = note } label: { noteCard(note, pinned: pinned) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(pinned ? "Unpin" : "Pin", systemImage: "pin") { pin(note) }
                            Button("Delete note", systemImage: "trash", role: .destructive) { delete(note) }
                        }
                }
            }
        }
    }

    private func noteCard(_ note: CoverTask, pinned: Bool) -> some View {
        HStack(spacing: 12) {
            if !pinned {
                Image(systemName: "note.text").foregroundStyle(CoverStyle.secondary)
                    .frame(width: 38, height: 38)
                    .background(EiraTheme.sageTint.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 5) {
                if pinned { Label("PINNED", systemImage: "pin").font(.system(size: 9)).foregroundStyle(CoverStyle.secondary) }
                Text(note.title).fontWeight(.semibold).lineLimit(1)
                let summary = (note.checklist ?? []).map(\.text).joined(separator: " · ")
                if let body = note.body, !body.isEmpty {
                    Text(body).font(.caption).foregroundStyle(CoverStyle.secondary).lineLimit(1)
                } else if !summary.isEmpty {
                    Text(summary).font(.caption).foregroundStyle(CoverStyle.secondary).lineLimit(1)
                }
                Text(note.createdAt, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 10)).foregroundStyle(CoverStyle.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if !pinned { Image(systemName: "chevron.right").font(.caption).foregroundStyle(CoverStyle.secondary) }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(pinned ? CoverStyle.pinned : .white, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(pinned ? CoverStyle.amber.opacity(0.3) : CoverStyle.border) }
    }

    private func pin(_ note: CoverTask) {
        var updated = note
        updated.isPinned = !(note.isPinned ?? false)
        do { try access.store.saveCoverTask(updated); Task { await load() } }
        catch { errorMessage = "Changes could not be saved. Try again." }
    }

    private func delete(_ note: CoverTask) {
        do { try access.store.deleteCoverTask(id: note.id); Task { await load() } }
        catch { errorMessage = "The note could not be deleted. Try again." }
    }

    private func load() async {
        do { notes = try access.store.coverTasks(); errorMessage = nil }
        catch { errorMessage = "The notes list could not be opened. Try again." }
    }
}

#Preview { CoverScreen(access: AccessFlow()) }
