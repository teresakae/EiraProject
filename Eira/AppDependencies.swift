// Shared swap points. Screens receive these dependencies when their phase is built.
@MainActor
struct AppDependencies {
    let store: any EiraStore
    let serverClient: any ServerClient

    init(store: any EiraStore = InMemoryEiraStore(), serverClient: any ServerClient = CannedServerClient()) {
        self.store = store
        self.serverClient = serverClient
    }
}
