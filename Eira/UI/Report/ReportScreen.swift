import SwiftUI

struct ReportScreen: View {
    @State private var flow: ReportFlow
    @State private var editing: ReportDraftField?
    @State private var showsPrivacy = false

    init(dependencies: AppDependencies) {
        _flow = State(initialValue: ReportFlow(dependencies: dependencies))
    }

    var body: some View {
        List {
            Section {
                Text("Periksa tiap isian bersama kata-kata sumbernya. Kamu bisa mengubah atau mengosongkannya.")
                    .foregroundStyle(.secondary)
                Button("Perbarui draf dari catatan") { Task { await flow.refresh() } }.disabled(flow.isWorking)
                if flow.isWorking { ProgressView("Memeriksa draf…") }
                if let message = flow.errorMessage { Text(message).foregroundStyle(.secondary) }
            }
            ForEach(flow.draft.fields) { field in
                Section {
                    ReportFieldSummary(field: field)
                    if ReportFields.missingRequired(in: flow.draft).contains(field.fieldName) {
                        Text("Formulir meminta isian ini.").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("Ubah") { editing = field }.buttonStyle(.borderless).disabled(flow.isWorking)
                        Spacer()
                        Button("Salin", systemImage: "doc.on.doc") {
                            Task {
                                if let text = await flow.copyText(for: field.fieldName) { ReportClipboard.copy(text) }
                            }
                        }.buttonStyle(.borderless).disabled(field.value == nil || flow.isWorking)
                    }
                } header: { Text(SafetyStrings.label(field.fieldName)) }
            }
            Section {
                Button("Tinjau sebelum membuka formulir") { Task { await flow.prepareConfirmation() } }
                    .disabled(flow.isWorking)
            }
        }
        .navigationTitle("Laporan")
        .toolbar { Button(SafetyStrings.privacyTitle, systemImage: "info.circle") { showsPrivacy = true } }
        .task { await flow.load() }
        .sheet(item: $editing) { field in ReportFieldEditor(field: field, flow: flow) }
        .sheet(isPresented: $showsPrivacy) { PrivacyCopyScreen() }
        .sheet(isPresented: Binding(get: { flow.stage != .review }, set: { if !$0 { flow.closeDelivery() } })) {
            NavigationStack {
                if let draft = flow.deliveryDraft {
                    if flow.stage == .confirmation {
                        ReportConfirmationScreen(draft: draft, flow: flow)
                    } else if flow.stage == .form {
                        ReportFormScreen(draft: draft, onClose: flow.closeDelivery)
                    }
                }
            }
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
            Text(SafetyStrings.display(field.value)).fixedSize(horizontal: false, vertical: true)
            Text(SafetyStrings.state(field.status)).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Kata-katamu").font(.caption).foregroundStyle(.secondary)
            Text(field.quote.map { "“\($0)”" } ?? (field.status == .editedByHer ? "Kamu mengisi sendiri." : "Belum ada sumber."))
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
                        Picker("Isian", selection: $text) {
                            Text("Kosong").tag("")
                            ForEach(options, id: \.self) { Text(SafetyStrings.choice($0)).tag($0) }
                        }.pickerStyle(.inline)
                    } else if ReportFields.isBoolean(field.fieldName) {
                        Picker("Isian", selection: $text) {
                            Text("Kosong").tag("")
                            Text("Ya").tag("true")
                            Text("Tidak").tag("false")
                        }.pickerStyle(.inline)
                    } else {
                        TextField("Isian", text: $text, axis: .vertical).lineLimit(3...12).autocorrectionDisabled()
                            .keyboardType(ReportFields.isPhone(field.fieldName) || field.fieldName == .victimAge ? .numberPad : .default)
                    }
                    if let quote = field.quote { Text("Kata-katamu: “\(quote)”").foregroundStyle(.secondary) }
                    Button("Kosongkan isian") { text = "" }
                }
                if let message = flow.errorMessage { Text(message).foregroundStyle(.secondary) }
            }
            .navigationTitle(SafetyStrings.label(field.fieldName)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
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
    let draft: ReportDraft
    let flow: ReportFlow

    var body: some View {
        List {
            Section {
                Text(SafetyStrings.draftNotice).font(.callout).foregroundStyle(.secondary)
                Text(SafetyStrings.shared)
            }
            Section("Isian yang akan dibagikan") {
                ForEach(draft.fields.filter { $0.value != nil }) { field in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(SafetyStrings.label(field.fieldName)).font(.headline)
                        ReportFieldSummary(field: field)
                    }
                }
            }
            Section("Dengan siapa") { Text(SafetyStrings.recipient) }
            Section("Kamu yang mengirim") { Text(SafetyStrings.sheSends) }
            Section("Yang belum diketahui") { Text(SafetyStrings.unknowns) }
            Section("Risiko") { Text(SafetyStrings.risks) }
            Section("Tentang identitas") { Text(SafetyStrings.anonymity) }
            Section {
                Text(SafetyStrings.mockNotice).foregroundStyle(.secondary)
                Button("Buka formulir uji") { Task { await flow.openConfirmedForm() } }.disabled(flow.isWorking)
                Button("Kembali ke draf") { flow.closeDelivery() }
            }
        }
        .navigationTitle(SafetyStrings.confirmationTitle).navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("report.confirmation")
        .toolbar { Button("Tutup") { flow.closeDelivery() } }
    }
}

#Preview { NavigationStack { ReportScreen(dependencies: AppDependencies()) } }
