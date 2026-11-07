import SwiftUI

// ponytail: fixed sample with no network or storage. Live status needs SAPA; see docs/ARCHITECTURE.md section 10.
enum ReportTrackerSample {
    // A real user must never see an invented status, so only mock builds show this screen.
    static func isAvailable(for target: ReportTarget = .current) -> Bool { target == .mock }
    static let currentStage = 2
}

struct ReportTrackerScreen: View {
    var onExit: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(SafetyStrings.trackerTitle).font(EiraTheme.title).foregroundStyle(EiraTheme.ink)
                Text(SafetyStrings.trackerNotice).font(EiraTheme.body).foregroundStyle(EiraTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12).background(EiraTheme.sageTint, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("tracker.notice")
                HStack {
                    Text("Reference").font(EiraTheme.body.weight(.medium)).foregroundStyle(EiraTheme.ink)
                    Spacer()
                    Text(SafetyStrings.trackerReference).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                }
                .padding(.horizontal, 16).frame(minHeight: 52)
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(EiraTheme.sageTint) }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(SafetyStrings.trackerStages.enumerated()), id: \.offset) { index, stage in
                        stageRow(index, title: stage.title, detail: stage.detail)
                    }
                }
                Text(SafetyStrings.trackerFootnote).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
        .background(EiraTheme.paper.ignoresSafeArea())
        .tint(EiraTheme.sage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) { EiraScreenTitle(text: "TRACKER") }
            ToolbarItem(placement: .topBarTrailing) { QuickExitButton(action: onExit) }
        }
        .accessibilityIdentifier("report.trackerScreen")
    }

    private func stageRow(_ index: Int, title: String, detail: String) -> some View {
        let current = ReportTrackerSample.currentStage
        let reached = index <= current
        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(reached ? EiraTheme.sage : EiraTheme.paper)
                    .overlay { Circle().stroke(EiraTheme.sage, lineWidth: 2) }
                    .frame(width: 14, height: 14)
                    .padding(.top, 4)
                if index < SafetyStrings.trackerStages.count - 1 {
                    Rectangle().fill(index < current ? EiraTheme.sage : EiraTheme.sageTint).frame(width: 2)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(EiraTheme.body.weight(index == current ? .bold : .regular))
                    .foregroundStyle(reached ? EiraTheme.ink : EiraTheme.sage)
                if index == current {
                    Text("Now").font(EiraTheme.micro.weight(.medium)).foregroundStyle(EiraTheme.sage)
                }
                Text(detail).font(EiraTheme.micro).foregroundStyle(EiraTheme.sage)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 20)
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityValue(index == current ? "Current step" : reached ? "Reached" : "Not reached")
    }
}

#Preview { NavigationStack { ReportTrackerScreen() } }
