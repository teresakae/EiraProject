import SwiftUI
import WebKit

enum ReportClipboard {
    @MainActor static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}

struct ReportFormScreen: View {
    let draft: ReportDraft
    let onClose: () -> Void
    let onFinished: () -> Void
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Text(SafetyStrings.mockNotice).font(.callout).foregroundStyle(.secondary).padding(.horizontal)
            if let errorMessage {
                Text(errorMessage).padding()
                Button("Back to draft", action: onClose)
                Spacer()
            } else {
                ReportFormWebView(draft: draft) { errorMessage = $0 }
            }
        }
        .navigationTitle("Test form").navigationBarTitleDisplayMode(.inline)
        .background(EiraTheme.paper.ignoresSafeArea())
        // A form that could not open returns to the draft; there was nothing she could send.
        .toolbar { Button("Close") { errorMessage == nil ? onFinished() : onClose() } }
    }
}

struct ReportFormWebView: UIViewRepresentable {
    let draft: ReportDraft
    var onFailure: (String) -> Void

    func makeCoordinator() -> ReportFormLoader {
        ReportFormLoader(draft: draft, target: ReportTarget.current, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> WKWebView { context.coordinator.makeWebView() }
    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: ReportFormLoader) {
        webView.stopLoading()
        webView.navigationDelegate = nil
    }
}

@MainActor
final class ReportFormLoader: NSObject, WKNavigationDelegate {
    private let draft: ReportDraft
    private let target: ReportTarget
    private let onFailure: (String) -> Void
    private let formURL = Bundle.main.url(forResource: "MockReportForm", withExtension: "html")
    private(set) var isFilled = false

    init(draft: ReportDraft, target: ReportTarget, onFailure: @escaping (String) -> Void) {
        self.draft = draft
        self.target = target
        self.onFailure = onFailure
    }

    func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.isInspectable = false
        // Real-form mapping is deferred: even a Release real target cannot open a network page.
        if target == .mock, let formURL {
            webView.loadFileURL(formURL, allowingReadAccessTo: formURL)
        } else {
            Task { @MainActor [onFailure, target] in
                onFailure(target == .real ? SafetyStrings.realDeferred : SafetyStrings.formUnavailable)
            }
        }
        return webView
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        let allowed = target == .mock && navigationAction.request.url == formURL
            && navigationAction.request.httpMethod == "GET" && navigationAction.targetFrame?.isMainFrame == true
        return allowed ? .allow : .cancel
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard target == .mock, webView.url == formURL, !isFilled else { return }
        var values: [String: Any] = [:]
        var specs: [[String: Any]] = []
        for name in ReportFieldName.allCases {
            let value = draft.fields.first { $0.fieldName == name }?.value
            guard ReportFields.valid(value, for: name) else { onFailure(SafetyStrings.formUnavailable); return }
            switch value {
            case .text(let text): values[name.rawValue] = text
            case .integer(let number): values[name.rawValue] = number
            case .boolean(let flag): values[name.rawValue] = flag
            case nil: values[name.rawValue] = NSNull()
            }
            var spec: [String: Any] = ["name": name.rawValue, "label": SafetyStrings.label(name)]
            if let options = ReportFields.options(for: name) { spec["options"] = options }
            spec["kind"] = ReportFields.isBoolean(name) ? "boolean"
                : name == .victimAge ? "integer" : ReportFields.isPhone(name) ? "phone" : "text"
            if let options = ReportFields.options(for: name) {
                spec["optionLabels"] = Dictionary(uniqueKeysWithValues: options.map { ($0, SafetyStrings.choice($0)) })
            }
            specs.append(spec)
        }
        // Arguments are data, including quotes, newlines and HTML in her text.
        webView.callAsyncJavaScript("return window.fillReport(values, specs)",
            arguments: ["values": values, "specs": specs], in: nil, in: .page, completionHandler: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let count):
                    self.isFilled = (count as? Int) == ReportFieldName.allCases.count
                    if !self.isFilled { self.onFailure(SafetyStrings.formUnavailable) }
                case .failure: self.onFailure(SafetyStrings.formUnavailable)
                }
            })
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        onFailure(SafetyStrings.formUnavailable)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        onFailure(SafetyStrings.formUnavailable)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        onFailure(SafetyStrings.formUnavailable)
    }
}
