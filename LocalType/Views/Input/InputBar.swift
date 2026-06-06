import SwiftUI

struct InputBar: View {
    @Environment(AppState.self) private var appState
    @Binding var showQuickPhrases: Bool

    var body: some View {
        @Bindable var state = appState

        HStack(alignment: .bottom, spacing: 10) {
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

            HStack(alignment: .bottom, spacing: 0) {
                TextField("输入文字...", text: $state.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 10)

                ZStack {
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
                }
                .frame(width: 44, height: 40)
                .offset(y: -1) // 向上微调 1 像素以抵消文本 Baseline 偏差
                .opacity(appState.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                .scaleEffect(appState.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.85 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: appState.inputText.isEmpty)
                .disabled(appState.inputText.trimmingCharacters(in: .whitespaces).isEmpty || appState.connectionStatus != .connected)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
