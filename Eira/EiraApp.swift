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
            .environment(\.locale, Locale(identifier: "en"))
            .transaction { $0.animation = nil }
            .onChange(of: phase) { _, phase in
                access.setInactive(phase != .active)
                if phase == .background { access.lock() }
            }
        }
    }
}
