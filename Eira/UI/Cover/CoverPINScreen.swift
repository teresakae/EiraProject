import SwiftUI

/// The access flow verifies the PIN; this screen keeps only the current input.
struct CoverPINScreen: View {
    var errorMessage: String? = nil
    let onCancel: () -> Void
    let onSubmit: (String) -> Void
    @State private var digits = ""
    private let letters = ["", "", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onCancel) { Label("Notes", systemImage: "chevron.left") }
                    .foregroundStyle(CoverStyle.amber)
                Spacer()
            }.padding(20)
            Spacer(minLength: 28)
            Image(systemName: "lock")
                .font(.system(size: 28)).foregroundStyle(CoverStyle.amber)
                .frame(width: 92, height: 92).background(CoverStyle.pinned, in: Circle())
            Text("This note is locked")
                .font(.custom("PlusJakartaSans-Regular", size: 24, relativeTo: .title2).bold())
                .padding(.top, 26)
            Text("Enter your PIN to open this note.")
                .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(CoverStyle.secondary).padding(.top, 12)
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    Circle().fill(index < digits.count ? CoverStyle.amber : .clear)
                        .frame(width: 14, height: 14)
                        .overlay { Circle().stroke(index < digits.count ? CoverStyle.amber : CoverStyle.secondary.opacity(0.5)) }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(digits.count) of 4 digits entered")
            .padding(.vertical, 40)
            Text(errorMessage ?? " ")
                .font(CoverStyle.body)
                .foregroundStyle(CoverStyle.secondary)
                .accessibilityIdentifier("access.pinError")
                .padding(.bottom, 8)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(1...9, id: \.self) { number in digitButton(number) }
                Button("Cancel", action: onCancel).font(CoverStyle.body).frame(minHeight: 64)
                digitButton(0)
                Button { if !digits.isEmpty { digits.removeLast() } } label: {
                    Image(systemName: "delete.left").frame(maxWidth: .infinity, minHeight: 64)
                }.accessibilityLabel("Delete last digit")
            }
            .padding(.horizontal, 36)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CoverStyle.background)
        .foregroundStyle(EiraTheme.ink).tint(CoverStyle.amber)
        .privacySensitive()
        .preferredColorScheme(.light)
        .onDisappear { digits = "" }
    }

    private func digitButton(_ number: Int) -> some View {
        Button {
            guard digits.count < 4 else { return }
            digits += String(number)
            if digits.count == 4 {
                let pin = digits
                digits = ""
                onSubmit(pin)
            }
        } label: {
            VStack(spacing: 4) {
                Text(String(number)).font(.custom("PlusJakartaSans-Regular", size: 28, relativeTo: .title))
                Text(letters[number]).font(.system(size: 9)).foregroundStyle(CoverStyle.secondary)
            }.frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(number))
        .accessibilityIdentifier("access.pinDigit.\(number)")
    }
}

#Preview { CoverPINScreen(onCancel: {}, onSubmit: { _ in }) }
