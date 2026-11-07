import SwiftUI

struct PrivateArea: View {
    let workspace: PrivateWorkspace
    let access: AccessFlow
    private enum Route: Hashable { case write, ask, summary, report(refresh: Bool), tracker }
    @State private var homePath: [Route] = []
    @State private var diaryPath: [Route] = []
    @State private var supportPath: [Route] = []
    @State private var hasNotedFacts = false

    var body: some View {
        TabView {
            NavigationStack(path: $homePath) {
                PrivateHomeScreen(flow: workspace.write, onWrite: { homePath.append(.write) }, onTalk: { homePath.append(.ask) })
                    .navigationDestination(for: Route.self) { destination($0, path: $homePath) }
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { quickExit } }
            }.tabItem { Label("Home", systemImage: "house") }
            NavigationStack(path: $diaryPath) {
                DiaryListScreen(flow: workspace.write)
                    .navigationDestination(for: Route.self) { destination($0, path: $diaryPath) }
                    .navigationTitle("Diary")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("New entry", systemImage: "square.and.pencil") { diaryPath.append(.write) }
                        }
                        ToolbarItem(placement: .topBarTrailing) { quickExit }
                    }
            }.tabItem { Label("Diary", systemImage: "book") }
            NavigationStack(path: $supportPath) {
                List {
                    Section {
                        NavigationLink(value: Route.ask) {
                            Label("Talk it through", systemImage: "bubble.left.and.bubble.right")
                        }
                        if hasNotedFacts {
                            NavigationLink(value: Route.summary) {
                                Label("What Eira noted", systemImage: "list.bullet.rectangle")
                            }.accessibilityIdentifier("support.summary")
                        }
                        NavigationLink(value: Route.report(refresh: false)) {
                            Label("Report draft", systemImage: "doc.text")
                        }
                        if ReportTrackerSample.isAvailable() {
                            NavigationLink(value: Route.tracker) {
                                Label("Report tracker (sample)", systemImage: "clock")
                            }.accessibilityIdentifier("support.tracker")
                        }
                    }
                    Section {
                        Button("Delete everything", role: .destructive) { Task { await access.deleteEverything() } }
                    }
                }
                .scrollContentBackground(.hidden).background(EiraTheme.paper)
                .navigationTitle("Support")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { quickExit } }
                .navigationDestination(for: Route.self) { destination($0, path: $supportPath) }
                .task {
                    let store = workspace.dependencies.store
                    let entries = (try? await store.entries()) ?? []
                    let facts = (try? await store.talkFacts()) ?? []
                    hasNotedFacts = TalkFacts.visible(facts, entries: entries).contains { !$0.value.isEmpty }
                }
            }.tabItem { Label("Support", systemImage: "heart") }
        }
        .tint(EiraTheme.sage)
        .font(EiraTheme.body)
        .preferredColorScheme(.light)
        .privacySensitive()
    }

    @ViewBuilder private func destination(_ route: Route, path: Binding<[Route]>) -> some View {
        switch route {
        case .write:
            WriteScreen(flow: workspace.write, voice: workspace.voice,
                onDone: { if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() } },
                onTalk: {
                    if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() }
                    path.wrappedValue.append(.ask)
                })
        case .ask:
            AskScreen(dependencies: workspace.dependencies, voice: workspace.voice,
                onSummary: { path.wrappedValue.append(.summary) },
                onExit: { access.lock() })
        case .summary:
            SummaryScreen(dependencies: workspace.dependencies,
                onKeepTalking: {
                    if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() }
                    if path.wrappedValue.last != .ask { path.wrappedValue.append(.ask) }
                },
                onUseInReport: { path.wrappedValue.append(.report(refresh: true)) },
                onExit: { access.lock() })
        case .report(let refresh):
            ReportScreen(dependencies: workspace.dependencies, refreshOnOpen: refresh,
                onExit: { access.lock() },
                onDelete: { Task { await access.deleteEverything() } })
        case .tracker:
            ReportTrackerScreen(onExit: { access.lock() })
        }
    }

    private var quickExit: some View { QuickExitButton { access.lock() } }
}

struct PrivateHomeScreen: View {
    @Bindable var flow: WriteFlow
    let onWrite: () -> Void
    let onTalk: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This is your private space").font(EiraTheme.title)
                    Text("It’s not your fault. Go at your own pace.").font(EiraTheme.body)
                }
                HStack(spacing: 8) {
                    homeAction("Write in diary", icon: "book", action: onWrite)
                    homeAction("Talk it through", icon: "bubble.left.and.bubble.right", action: onTalk)
                }
                Text("Diary").font(EiraTheme.action)
                DiaryRows(flow: flow)
                if let message = flow.errorMessage { Text(message).foregroundStyle(.secondary) }
            }.padding(.horizontal, 20).padding(.top, 20)
        }
        .background(EiraTheme.paper)
        .foregroundStyle(EiraTheme.sage)
        .task { await flow.load() }
    }

    private func homeAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon).font(.system(size: 24))
                    .frame(width: 40, height: 40).background(EiraTheme.sageTint, in: Circle())
                Text(title).font(EiraTheme.body)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
        }.buttonStyle(.plain)
    }
}

struct DiaryListScreen: View {
    @Bindable var flow: WriteFlow
    var body: some View {
        ScrollView { DiaryRows(flow: flow).padding(20) }
            .background(EiraTheme.paper).task { await flow.load() }
    }
}

extension View {
    // Practice tool: hold a record, then tap Delete. Compiled out of Release builds.
    @ViewBuilder func debugHoldToDelete(_ action: @escaping () -> Void) -> some View {
        #if DEBUG
        contextMenu { Button("Delete", systemImage: "trash", role: .destructive, action: action) }
        #else
        self
        #endif
    }
}

private struct DiaryRows: View {
    @Bindable var flow: WriteFlow
    var body: some View {
        VStack(spacing: 0) {
            if flow.entries.isEmpty {
                Text("No entries yet.").foregroundStyle(.secondary).padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(flow.entries.reversed()) { entry in
                NavigationLink {
                    DiaryEntryScreen(flow: flow, entryID: entry.id)
                } label: {
                    HStack(spacing: 16) {
                        Text(entry.createdAt, format: .dateTime.day().month(.abbreviated))
                            .frame(width: 54, alignment: .leading)
                        Text(entry.text).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }.padding(.horizontal, 16).padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .debugHoldToDelete { Task { await flow.deleteEntry(entry.id) } }
                if entry.id != flow.entries.first?.id { Divider().overlay(EiraTheme.sageTint).padding(.horizontal, 16) }
            }
        }
        .font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
    }
}

private struct DiaryEntryScreen: View {
    @Bindable var flow: WriteFlow
    let entryID: UUID
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            if let entry = flow.entries.first(where: { $0.id == entryID }) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(entry.createdAt, format: .dateTime.day().month(.wide).hour().minute()).font(EiraTheme.micro)
                    Text(entry.text).font(EiraTheme.story).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20).background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    AllowedUsesControl(entry: entry) { await flow.setUses($0, for: entry.id) }
                    if let reply = entry.writeReply { Text(reply) }
                    ForEach(flow.timeline.filter { $0.entryID == entry.id }) { event in
                        VStack(alignment: .leading, spacing: 10) {
                            if let when = event.whenText { Text(when).font(EiraTheme.micro) }
                            Text(event.whatHappened)
                            Text("“\(event.quote)”").font(EiraTheme.story)
                            if let injuries = event.injuries { Text("Injuries: \(injuries)") }
                            if !event.witnesses.isEmpty { Text("Witnesses: \(event.witnesses.joined(separator: ", "))") }
                            Picker(event.userEdited ? "Type · Edited by you" : "Type · Suggested", selection: Binding(
                                get: { event.violenceType },
                                set: { type in Task { await flow.setType(type, for: event.id) } }
                            )) {
                                Text("Physical").tag(ViolenceType.physical)
                                Text("Psychological").tag(ViolenceType.psychological)
                                Text("Sexual").tag(ViolenceType.sexual)
                                Text("Neglect").tag(ViolenceType.neglect)
                                Text("Not sure").tag(ViolenceType.unsure)
                            }
                        }.padding(16).background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button("Delete entry", role: .destructive) {
                        Task { await flow.deleteEntry(entry.id); if !flow.entries.contains(where: { $0.id == entry.id }) { dismiss() } }
                    }
                }.padding(20)
            }
        }
        .background(EiraTheme.paper).foregroundStyle(EiraTheme.sage)
        .navigationTitle("Diary entry").navigationBarTitleDisplayMode(.inline)
    }
}
