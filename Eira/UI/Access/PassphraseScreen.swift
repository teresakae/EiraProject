import SwiftUI

struct PassphraseScreen: View {
    let access: AccessFlow
    let setup: Bool
    @State private var passphrase = ""
    @State private var confirmation = ""
    @State private var isWorking = false
    @State private var operation: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(setup ? "Buat frasa sandi" : "Frasa sandi", text: $passphrase)
                        .accessibilityIdentifier("access.passphrase")
                    if setup {
                        SecureField("Ulangi frasa sandi", text: $confirmation)
                            .accessibilityIdentifier("access.confirmation")
                    }
                } footer: {
                    if setup {
                        Text("Pilih frasa sandi pribadi yang bisa kamu ingat. Tidak ada pemulihan. Kalau lupa, catatanmu tidak bisa dibuka kembali.")
                    }
                }
                if let message = access.errorMessage { Text(message).foregroundStyle(.secondary) }
                Button(setup ? "Simpan dan buka" : "Buka") {
                    isWorking = true
                    let secret = passphrase
                    passphrase = ""
                    confirmation = ""
                    operation = Task { _ = await access.open(passphrase: secret); isWorking = false }
                }
                .disabled(isWorking || passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || (setup && passphrase != confirmation))
                .accessibilityIdentifier("access.open")
                if isWorking { ProgressView("Membuka…") }
            }
            .navigationTitle(setup ? "Buat frasa sandi" : "Masukkan frasa sandi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Batal") { operation?.cancel(); access.cancelAccess() } }
        }
        .privacySensitive()
        .onDisappear { passphrase = ""; confirmation = ""; operation?.cancel() }
    }
}
