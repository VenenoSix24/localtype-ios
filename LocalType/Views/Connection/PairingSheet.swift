import SwiftUI

struct PairingSheet: View {
    @Environment(AppState.self) private var appState
    @State private var code: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("输入配对码")
                .font(.title3.weight(.semibold))

            // Code boxes
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let char = index < code.count ? String(Array(code)[index]) : ""
                    Text(char)
                        .font(.title2.bold())
                        .monospaced()
                        .frame(width: 40, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(index < code.count ? Color.blue.opacity(0.12) : Color(.tertiarySystemFill))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(index == code.count ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
            }
            .overlay {
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .opacity(0.01)
                    .frame(width: 1, height: 1)
            }
            .onTapGesture { isFocused = true }
            .onChange(of: code) { _, new in
                code = String(new.prefix(6).filter { $0.isNumber })
                if code.count == 6 {
                    HapticManager.notification(.success)
                    appState.submitPairingCode(code)
                }
            }

            // Buttons
            HStack(spacing: 12) {
                Button {
                    appState.disconnect()
                } label: {
                    Text("取消")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                        .foregroundStyle(Color.primary)
                }

                Button {
                    appState.submitPairingCode(code)
                } label: {
                    Text("确认")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue, in: .rect(cornerRadius: 12))
                        .foregroundStyle(Color.white)
                }
                .disabled(code.count < 6)
                .opacity(code.count < 6 ? 0.5 : 1)
            }
            .font(.subheadline)
        }
        .padding(28)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .padding(.horizontal, 36)
    }
}
