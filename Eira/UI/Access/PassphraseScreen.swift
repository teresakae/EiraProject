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
                    SecureField("Frasa sandi lama", text: $passphrase)
                        .accessibilityIdentifier("access.passphrase")
                } footer: {
                    Text("Masukkan frasa sandi lama sekali untuk membuka dan memindahkan catatan yang sudah ada. Setelah itu, kamu tidak perlu memasukkannya lagi.")
                }
                if let message = access.errorMessage { Text(message).foregroundStyle(.secondary) }
                Button("Buka catatan") {
                    isWorking = true
                    let secret = passphrase
                    passphrase = ""
                    operation = Task { _ = await access.open(passphrase: secret); isWorking = false }
                }
                .disabled(isWorking || passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("access.open")
                if isWorking { ProgressView("Membuka…") }
            }
            .navigationTitle("Buka catatan yang sudah ada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Batal") { operation?.cancel(); access.cancelAccess() } }
        }
        .privacySensitive()
        .onDisappear { passphrase = ""; operation?.cancel() }
    }
}
