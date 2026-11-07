import SwiftUI

struct SummaryScreen: View {
    @State private var flow: SummaryFlow
    private let onKeepTalking: () -> Void
    private let onUseInReport: () -> Void
    private let onExit: () -> Void
    @State private var editing: TalkFactCategory?
    @State private var isShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(dependencies: AppDependencies, onKeepTalking: @escaping () -> Void,
         onUseInReport: @escaping () -> Void, onExit: @escaping () -> Void) {
        _flow = State(initialValue: SummaryFlow(dependencies: dependencies))
        self.onKeepTalking = onKeepTalking
        self.onUseInReport = onUseInReport
        self.onExit = onExit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SafetyStrings.summaryTitle).font(EiraTheme.title).foregroundStyle(EiraTheme.ink)
                    Text(SafetyStrings.summaryIntro).font(EiraTheme.body).foregroundStyle(EiraTheme.sage)
                }.padding(.bottom, 20).arriving(0, isShown: isShown, reduceMotion: reduceMotion)

                ForEach(Array(TalkFactCategory.allCases.enumerated()), id: \.element) { index, category in
                    Divider().overlay(EiraTheme.sageTint)
                    row(category).arriving(index + 1, isShown: isShown, reduceMotion: reduceMotion)
                }
                Divider().overlay(EiraTheme.sageTint)

                if !flow.references.isEmpty {
                    legalCard.padding(.top, 20).arriving(5, isShown: isShown, reduceMotion: reduceMotion)
                    Text(SafetyStrings.legalFootnote).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                        .padding(.top, 12)
                }
                if let error = flow.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.secondary).padding(.top, 12)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "SUMMARY") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .task {
            await flow.load()
            isShown = true
        }
        .sheet(item: $editing) { category in
            SummaryFixEditor(category: category, initial: flow.value(for: category), flow: flow)
        }
    }

    private func row(_ category: TalkFactCategory) -> some View {
        let value = flow.value(for: category)
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(category.rawValue.uppercased())
                .font(EiraTheme.micro.weight(.medium)).tracking(1).foregroundStyle(EiraTheme.sage)
                .frame(width: 58, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(value.isEmpty ? SafetyStrings.summaryEmpty : value)
                    .font(EiraTheme.body).foregroundStyle(value.isEmpty ? Color.secondary : EiraTheme.ink)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: value)
                if flow.isEdited(category) {
                    Text(SafetyStrings.state(.editedByHer)).font(EiraTheme.micro).foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Button("Fix") { editing = category }
                .font(EiraTheme.body.weight(.semibold)).foregroundStyle(EiraTheme.sage)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Fix \(category.rawValue)")
                .accessibilityIdentifier("summary.fix.\(category.rawValue)")
        }.padding(.vertical, 4)
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(SafetyStrings.legalHeading) · \(LegalReferences.lawName)")
                .font(EiraTheme.micro.weight(.medium)).tracking(0.8).foregroundStyle(EiraTheme.sage)
            ForEach(Array(flow.references.enumerated()), id: \.element.id) { index, reference in
                if index > 0 { Divider().overlay(EiraTheme.sageTint) }
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(reference.article) · \(reference.title)")
                        .font(EiraTheme.story.weight(.semibold)).foregroundStyle(EiraTheme.ink)
                    Text(SafetyStrings.legalBecause).font(EiraTheme.micro.weight(.semibold)).foregroundStyle(EiraTheme.sage)
                    Text(reference.reason).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12).background(EiraTheme.sageTint, in: RoundedRectangle(cornerRadius: 10))
                    Text(SafetyStrings.legalConsequence).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                }
            }
        }
        .padding(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(EiraTheme.sage.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .accessibilityIdentifier("summary.legal")
    }

    private var actions: some View {
        VStack(spacing: 6) {
            Button(action: onUseInReport) {
                Text("Use this in my report").font(EiraTheme.action).foregroundStyle(EiraTheme.paper)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(EiraTheme.sage, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("summary.useInReport")
            Button("Something’s wrong, keep talking", action: onKeepTalking)
                .font(EiraTheme.body.weight(.semibold)).underline().foregroundStyle(EiraTheme.sage)
                .frame(minHeight: 44)
                .accessibilityIdentifier("summary.keepTalking")
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
        .background(EiraTheme.paper)
    }
}

extension TalkFactCategory: Identifiable {
    var id: String { rawValue }
}

private struct SummaryFixEditor: View {
    let category: TalkFactCategory
    let flow: SummaryFlow
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(category: TalkFactCategory, initial: String, flow: SummaryFlow) {
        self.category = category
        self.flow = flow
        _text = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(SafetyStrings.factLabel(category), text: $text, axis: .vertical)
                        .lineLimit(2...8).autocorrectionDisabled()
                        .accessibilityIdentifier("summary.fix.input")
                } footer: {
                    Text("Your words replace what Eira noted. Leave this empty to remove it.")
                }
                if let error = flow.errorMessage { Text(error).foregroundStyle(.secondary) }
            }
            .scrollContentBackground(.hidden).background(EiraTheme.paper)
            .navigationTitle("Fix \(category.rawValue)").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { if await flow.fix(category, text: text) { dismiss() } } }
                        .disabled(flow.isSaving)
                }
            }
        }.presentationDetents([.medium])
    }
}

private extension View {
    func arriving(_ index: Int, isShown: Bool, reduceMotion: Bool) -> some View {
        opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : 6)
            .animation(.easeOut(duration: 0.25).delay(reduceMotion ? 0 : Double(index) * 0.04), value: isShown)
    }
}
