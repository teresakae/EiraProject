import SwiftUI

struct PassphraseScreen: View {
    let access: AccessFlow
    @State private var passphrase = ""
    @State private var isWorking = false
    @State private var operation: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Old passphrase", text: $passphrase)
                        .accessibilityIdentifier("access.passphrase")
                } footer: {
                    Text("Enter your old passphrase once to open and convert your existing entries. You will not need it again.")
                }
                if let message = access.errorMessage { Text(message).foregroundStyle(.secondary) }
                Button("Open entries") {
                    isWorking = true
                    let secret = passphrase
                    passphrase = ""
                    operation = Task { _ = await access.open(passphrase: secret); isWorking = false }
                }
                .disabled(isWorking || passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("access.open")
                if isWorking { ProgressView("Opening…") }
            }
            .navigationTitle("Open existing entries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Cancel") { operation?.cancel(); access.cancelAccess() } }
        }
        .privacySensitive()
        .onDisappear { passphrase = ""; operation?.cancel() }
    }
}
