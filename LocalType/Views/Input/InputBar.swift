import SwiftUI

struct InputBar: View {
    @Environment(AppState.self) private var appState
    @Binding var showQuickPhrases: Bool

    var body: some View {
        @Bindable var state = appState

        HStack(alignment: .center, spacing: 10) {
            // Plus button - matches single-line text field height
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showQuickPhrases.toggle()
                }
                HapticManager.selection()
            } label: {
                Image(systemName: showQuickPhrases ? "chevron.down" : "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .glassEffect(.regular, in: .circle)
            }
            .frame(height: 38)

            // Text field with send button at bottom-right
            HStack(alignment: .bottom, spacing: 0) {
                TextField("输入文字...", text: $state.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                // Send button pinned to bottom
                Button {
                    appState.sendText()
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue, in: .circle)
                }
                .padding(.trailing, 8)
                .padding(.bottom, 8)
                .opacity(appState.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                .disabled(appState.inputText.trimmingCharacters(in: .whitespaces).isEmpty || appState.connectionStatus != .connected)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
