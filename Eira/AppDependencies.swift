// Shared swap points. Screens receive these dependencies when their phase is built.
@MainActor
struct AppDependencies {
    let store: any EiraStore
    let serverClient: any ServerClient
    let lifetime: SessionLifetime?

    init(store: any EiraStore = InMemoryEiraStore(), serverClient: any ServerClient = CannedServerClient(),
         lifetime: SessionLifetime? = nil) {
        self.store = store
        self.serverClient = serverClient
        self.lifetime = lifetime
    }
}

@MainActor
final class SessionLifetime {
    private var cleanups: [() -> Void] = []
    private var ended = false

    func onLock(_ cleanup: @escaping () -> Void) {
        if ended { cleanup() } else { cleanups.append(cleanup) }
    }

    func lock() {
        ended = true
        let pending = cleanups
        cleanups = []
        pending.forEach { $0() }
    }
}
