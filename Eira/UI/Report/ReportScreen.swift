import SwiftUI

private enum ReportFieldGroup: String, CaseIterable, Identifiable {
    case whatHappened = "What happened"
    case whenAndWhere = "When & where"
    case aboutThePerson = "Person affected"
    case aboutYou = "About you"
    case contact = "Your contact"

    var id: String { rawValue }

    var fields: [ReportFieldName] {
        switch self {
        case .whatHappened: [.description, .levelConcern]
        case .whenAndWhere: [.incidentTime, .location, .provinceCity]
        case .aboutThePerson: [.isVictim, .relationshipWithVictim, .victimFullName, .victimGender, .victimAge,
            .victimDisabilities, .victimDisabilitiesType, .victimContactNumber, .victimTrustedPerson]
        case .aboutYou: [.reporterFullName, .anonymous]
        case .contact: [.contactNumber]
        }
    }

    // Plain information about what the form asks for, never a count or a tick (C8, C17).
    func state(in draft: ReportDraft) -> String {
        let values = draft.fields.filter { fields.contains($0.fieldName) }
        if values.allSatisfy({ $0.value == nil }) { return "Empty" }
        return fields.contains(where: ReportFields.missingRequired(in: draft).contains) ? "Some empty" : "Filled"
    }
}

struct ReportScreen: View {
    @State private var flow: ReportFlow
    @State private var showsPrivacy = false
    private let refreshOnOpen: Bool
    private let onExit: () -> Void
    private let onDelete: () -> Void

    init(dependencies: AppDependencies, refreshOnOpen: Bool = false,
         onExit: @escaping () -> Void = {}, onDelete: @escaping () -> Void = {}) {
        _flow = State(initialValue: ReportFlow(dependencies: dependencies))
        self.refreshOnOpen = refreshOnOpen
        self.onExit = onExit
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SafetyStrings.reportTitle).font(EiraTheme.title).foregroundStyle(EiraTheme.ink)
                    Text(SafetyStrings.reportIntro).font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
                }
                if flow.isWorking { ProgressView("Checking draft…").font(EiraTheme.micro) }
                if let message = flow.errorMessage {
                    Text(message).font(EiraTheme.micro).foregroundStyle(.secondary)
                }
                groupRows
                if !flow.references.isEmpty { references }
                contactChoice
                VStack(alignment: .leading, spacing: 4) {
                    ReportQuietButton(title: "Refresh draft from entries") { Task { await flow.refresh() } }
                        .disabled(flow.isWorking)
                    ReportQuietButton(title: SafetyStrings.privacyTitle) { showsPrivacy = true }
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ReportPrimaryButton(title: "Review before sending") { Task { await flow.prepareConfirmation() } }
                .disabled(flow.isWorking)
                .accessibilityIdentifier("report.review")
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
                .background(EiraTheme.paper)
        }
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "REPORT") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .task {
            await flow.load()
            if refreshOnOpen { await flow.refresh() } else { await flow.fillIfEmpty() }
        }
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .navigationDestination(isPresented: Binding(
            get: { flow.stage != .review },
            set: { if !$0 { flow.closeDelivery() } })) {
                switch flow.stage {
                case .review: EmptyView()
                case .confirmation: ReportConfirmationScreen(flow: flow, onExit: onExit)
                case .form:
                    if let draft = flow.formDraft {
                        ReportFormScreen(draft: draft, onClose: flow.closeDelivery, onFinished: flow.finishForm)
                            .navigationBarBackButtonHidden()
                    }
                case .afterSend: ReportAfterSendScreen(flow: flow, onExit: onExit, onDelete: onDelete)
                }
            }
    }

    private var groupRows: some View {
        VStack(spacing: 0) {
            ForEach(ReportFieldGroup.allCases) { group in
                NavigationLink {
                    ReportGroupScreen(group: group, flow: flow, onExit: onExit)
                } label: {
                    ReportRow(title: group.rawValue, detail: group.state(in: flow.draft), showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("report.group.\(group.id)")
                if group != ReportFieldGroup.allCases.last { Divider().overlay(EiraTheme.sageTint).padding(.horizontal, 16) }
            }
        }
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
    }

    private var references: some View {
        VStack(alignment: .leading, spacing: 8) {
            ReportRow(title: "May fall under",
                      detail: flow.references.map(\.article).joined(separator: ", "), showsChevron: false)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(EiraTheme.sage.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            Text(SafetyStrings.referencesNotSent + SafetyStrings.legalFootnote)
                .font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
        }
        .accessibilityIdentifier("report.references")
    }

    private var contactChoice: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(SafetyStrings.reportReachTitle).font(EiraTheme.action).foregroundStyle(EiraTheme.ink)
                .padding(.bottom, 4)
            choice("No preference", .noPreference, id: "noPreference")
            choice("No WhatsApp messages, calls are OK", .noWhatsApp, id: "noWhatsApp")
            choice("WhatsApp messages are OK, please don’t call", .whatsAppOK, id: "whatsAppOK")
            Text(SafetyStrings.reportReachNote).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
        }
    }

    private func choice(_ title: String, _ value: ReportFlow.ContactPreference, id: String) -> some View {
        let isSelected = flow.contactPreference == value
        return Button { flow.contactPreference = value } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle").font(.system(size: 20))
                    .foregroundStyle(EiraTheme.sage)
                Text(title).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("report.contact.\(id)")
    }
}

private struct ReportRow: View {
    let title: String
    let detail: String
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(EiraTheme.body.weight(.medium)).foregroundStyle(EiraTheme.ink)
            Spacer(minLength: 8)
            Text(detail).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage).multilineTextAlignment(.trailing)
            if showsChevron { Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(EiraTheme.sage) }
        }
        .padding(.horizontal, 16).frame(minHeight: 52).contentShape(Rectangle())
    }
}

struct ReportPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(EiraTheme.action).foregroundStyle(EiraTheme.paper)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(EiraTheme.sage, in: Capsule())
        }.buttonStyle(.plain)
    }
}

private struct ReportOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(EiraTheme.action).foregroundStyle(EiraTheme.sage)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay { Capsule().stroke(EiraTheme.sage.opacity(0.5)) }
                .contentShape(Capsule())
        }.buttonStyle(.plain)
    }
}

private struct ReportQuietButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(EiraTheme.body.weight(.semibold)).underline().foregroundStyle(EiraTheme.sage)
            .frame(minHeight: 44)
    }
}

private struct ReportGroupScreen: View {
    let group: ReportFieldGroup
    let flow: ReportFlow
    let onExit: () -> Void
    @State private var editing: ReportDraftField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(group.rawValue).font(EiraTheme.title).foregroundStyle(EiraTheme.ink).padding(.bottom, 8)
                Text("Check each field against your source words. You can edit or clear it.")
                    .font(EiraTheme.body).foregroundStyle(EiraTheme.sage).padding(.bottom, 20)
                ForEach(flow.draft.fields.filter { group.fields.contains($0.fieldName) }) { field in
                    Divider().overlay(EiraTheme.sageTint)
                    fieldRow(field).padding(.vertical, 12)
                }
                Divider().overlay(EiraTheme.sageTint)
                if let message = flow.errorMessage {
                    Text(message).font(EiraTheme.micro).foregroundStyle(.secondary).padding(.top, 12)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "REPORT") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .sheet(item: $editing) { ReportFieldEditor(field: $0, flow: flow) }
    }

    private func fieldRow(_ field: ReportDraftField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SafetyStrings.label(field.fieldName)).font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.ink)
            ReportFieldSummary(field: field).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
            if let note = SafetyStrings.fieldNote(field.fieldName) {
                Text(note).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage).fixedSize(horizontal: false, vertical: true)
            }
            if ReportFields.missingRequired(in: flow.draft).contains(field.fieldName) {
                Text("The form requires this field.").font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
            }
            HStack {
                Button("Edit") { editing = field }.disabled(flow.isWorking)
                    .accessibilityLabel("Edit \(SafetyStrings.label(field.fieldName))")
                Spacer()
                Button("Copy", systemImage: "doc.on.doc") {
                    Task {
                        if let text = await flow.copyText(for: field.fieldName) { ReportClipboard.copy(text) }
                    }
                }.disabled(field.value == nil || flow.isWorking)
                    .accessibilityLabel("Copy \(SafetyStrings.label(field.fieldName))")
            }
            .font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.sage).frame(minHeight: 44)
        }
    }
}

struct ReportFieldSummary: View {
    let field: ReportDraftField
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) { value; source }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 20) {
                        value.frame(minWidth: 110, maxWidth: .infinity, alignment: .leading)
                        source.frame(minWidth: 110, maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 12) { value; source }
                }
            }
        }.padding(.vertical, 4)
    }

    private var value: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(SafetyStrings.display(field.value, for: field.fieldName)).fixedSize(horizontal: false, vertical: true)
            Text(SafetyStrings.state(field.status)).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your words").font(.caption).foregroundStyle(.secondary)
            Text(field.quote.map { "“\($0)”" } ?? (field.status == .editedByHer ? "You entered this yourself." : "No source yet."))
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReportFieldEditor: View {
    let field: ReportDraftField
    let flow: ReportFlow
    @State private var text: String
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(field: ReportDraftField, flow: ReportFlow) {
        self.field = field
        self.flow = flow
        _text = State(initialValue: ReportFields.text(field.value))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let options = ReportFields.options(for: field.fieldName) {
                        Picker("Field", selection: $text) {
                            Text("Empty").tag("")
                            ForEach(options, id: \.self) { Text(SafetyStrings.choice($0)).tag($0) }
                        }.pickerStyle(.inline)
                    } else if ReportFields.isBoolean(field.fieldName) {
                        Picker("Field", selection: $text) {
                            Text("Empty").tag("")
                            Text("Yes").tag("true")
                            Text("No").tag("false")
                        }.pickerStyle(.inline)
                    } else {
                        TextField("Field", text: $text, axis: .vertical).lineLimit(3...12).autocorrectionDisabled()
                            .keyboardType(ReportFields.isPhone(field.fieldName) || field.fieldName == .victimAge ? .numberPad : .default)
                    }
                    if let quote = field.quote { Text("Your words: “\(quote)”").foregroundStyle(.secondary) }
                    Button("Clear field") { text = "" }
                }
                if let message = flow.errorMessage { Text(message).foregroundStyle(.secondary) }
            }
            .scrollContentBackground(.hidden).background(EiraTheme.paper)
            .navigationTitle(SafetyStrings.label(field.fieldName)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            if await flow.edit(field.fieldName, text: text) { dismiss() }
                            isSaving = false
                        }
                    }.disabled(isSaving)
                }
            }
        }.interactiveDismissDisabled(isSaving)
    }
}

struct ReportConfirmationScreen: View {
    let flow: ReportFlow
    var onExit: () -> Void = {}
    @State private var editing: ReportDraftField?

    private var filled: [ReportDraftField] { (flow.formDraft ?? flow.draft).fields.filter { $0.value != nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SafetyStrings.reviewTitle).font(EiraTheme.title).foregroundStyle(EiraTheme.ink)
                    Text(SafetyStrings.reviewIntro).font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
                }
                card
                section("SENT TO", SafetyStrings.recipient)
                section("WHAT IS SHARED", SafetyStrings.shared)
                section("YOU DECIDE WHEN TO SEND", SafetyStrings.sheSends)
                section("WHAT WE DO NOT KNOW", SafetyStrings.unknowns)
                section("RISKS", SafetyStrings.risks)
                section("ABOUT YOUR IDENTITY", SafetyStrings.anonymity)
                Text(SafetyStrings.draftNotice).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                if let message = flow.errorMessage {
                    Text(message).font(EiraTheme.micro).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "REVIEW") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .accessibilityIdentifier("report.confirmation")
        // Edit the saved field, not the review copy that may carry the contact line.
        .sheet(item: $editing) { field in
            ReportFieldEditor(field: flow.draft.fields.first { $0.fieldName == field.fieldName } ?? field, flow: flow)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            if filled.isEmpty {
                Text("Nothing is filled in yet.").font(EiraTheme.body).foregroundStyle(.secondary)
            }
            ForEach(filled) { field in
                Button { editing = field } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SafetyStrings.label(field.fieldName)).font(EiraTheme.micro.weight(.medium)).foregroundStyle(EiraTheme.sage)
                        Text(SafetyStrings.display(field.value, for: field.fieldName)).font(EiraTheme.story).foregroundStyle(EiraTheme.ink)
                        Text(field.quote.map { "Your words: “\($0)”" } ?? "You entered this yourself.")
                            .font(EiraTheme.micro).foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Change this field")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EiraTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(EiraTheme.micro.weight(.medium)).tracking(1).foregroundStyle(EiraTheme.sage)
            Text(text).font(EiraTheme.body).foregroundStyle(EiraTheme.ink).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            ReportPrimaryButton(title: "Open form to fill") { Task { await flow.openConfirmedForm() } }
                .disabled(flow.isWorking)
                .accessibilityIdentifier("report.openForm")
            ReportOutlineButton(title: "Copy text instead") {
                Task { if let text = await flow.copyAllText() { ReportClipboard.copy(text) } }
            }
            .accessibilityIdentifier("report.copyAll")
            Text(SafetyStrings.neverSends).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
        .background(EiraTheme.paper)
    }
}

struct ReportAfterSendScreen: View {
    let flow: ReportFlow
    var onExit: () -> Void = {}
    var onDelete: () -> Void = {}
    // Only changes this screen. Her answer is never stored or sent.
    @State private var saidSent = false
    @State private var confirmsDelete = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SafetyStrings.afterSendTitle).font(EiraTheme.title).foregroundStyle(EiraTheme.ink)
                    Text(SafetyStrings.afterSendIntro).font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
                }
                if saidSent {
                    Text(SafetyStrings.afterSendConfirmed).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12).background(EiraTheme.sageTint, in: RoundedRectangle(cornerRadius: 10))
                    nextSteps.transition(.opacity)
                    if ReportTrackerSample.isAvailable() {
                        NavigationLink { ReportTrackerScreen(onExit: onExit) } label: {
                            ReportRow(title: SafetyStrings.trackerLink, detail: "Sample", showsChevron: true)
                                .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("report.tracker")
                    }
                } else {
                    HStack(spacing: 8) {
                        ReportPrimaryButton(title: "Yes, I sent it") {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { saidSent = true }
                        }.accessibilityIdentifier("report.sent.yes")
                        ReportOutlineButton(title: "Not yet") { Task { await flow.prepareConfirmation() } }
                            .accessibilityIdentifier("report.sent.notYet")
                    }
                }
                if let message = flow.errorMessage {
                    Text(message).font(EiraTheme.micro).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { keepCard }
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "REPORT") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .accessibilityIdentifier("report.afterSend")
    }

    private var nextSteps: some View {
        let steps = SafetyStrings.nextSteps(contact: flow.contactPreference)
        return VStack(alignment: .leading, spacing: 16) {
            Text(SafetyStrings.nextStepsHeading).font(EiraTheme.micro.weight(.medium)).tracking(1).foregroundStyle(EiraTheme.sage)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)").font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.sage)
                        .frame(width: 32, height: 32).background(EiraTheme.sageTint, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title).font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.ink)
                        Text(step.detail).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var keepCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(SafetyStrings.keepRecordsTitle).font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.ink)
                Text(SafetyStrings.keepRecordsDetail).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
            }
            Spacer(minLength: 0)
            Button("Delete") { confirmsDelete = true }
                .font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.clay)
                .padding(.horizontal, 16).frame(minHeight: 44)
                .overlay { Capsule().stroke(EiraTheme.clay.opacity(0.5)) }
                .accessibilityIdentifier("report.delete")
        }
        .padding(16)
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
        .background(EiraTheme.paper)
        .confirmationDialog(SafetyStrings.deleteConfirmTitle, isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive, action: onDelete)
        }
    }
}

#Preview { NavigationStack { ReportScreen(dependencies: AppDependencies()) } }
