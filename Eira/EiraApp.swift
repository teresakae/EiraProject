import SwiftUI

@main
struct EiraApp: App {
    @State private var access = AccessFlow(client: HTTPServerClient.configured())
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Group {
                if access.isInactive {
                    CoverScreen(access: access).allowsHitTesting(false)
                } else if let workspace = access.workspace {
                    PrivateArea(workspace: workspace, access: access).id(workspace.id)
                } else if access.gate == .pin {
                    CoverPINScreen(errorMessage: access.errorMessage,
                                   onCancel: { access.cancelAccess() },
                                   onSubmit: { _ = access.submitPIN($0) })
                } else if access.gate == .migration {
                    PassphraseScreen(access: access)
                } else {
                    CoverScreen(access: access)
                }
            }
            .transaction { $0.animation = nil }
            .onChange(of: phase) { _, phase in
                access.setInactive(phase != .active)
                if phase == .background { access.lock() }
            }
        }
    }
}

private struct PrivateArea: View {
    let workspace: PrivateWorkspace
    let access: AccessFlow

    var body: some View {
        TabView {
            NavigationStack {
                WriteScreen(flow: workspace.write, voice: workspace.voice)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { Button("Tutup") { access.lock() } }
                        ToolbarItem(placement: .bottomBar) {
                            Button("Hapus semuanya", role: .destructive) { Task { await access.deleteEverything() } }
                        }
                    }
            }.tabItem { Label("Tulis", systemImage: "square.and.pencil") }
            NavigationStack { AskScreen(dependencies: workspace.dependencies) }
                .tabItem { Label("Tanya", systemImage: "bubble.left") }
            NavigationStack { ReportScreen(dependencies: workspace.dependencies) }
                .tabItem { Label("Laporan", systemImage: "doc.text") }
        }.privacySensitive()
    }
}
