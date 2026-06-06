import SwiftUI

struct QuickPhrasePanel: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    var body: some View {
        if appState.quickPhrases.isEmpty {
            HStack {
                Text("暂无快捷短语")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .padding(.horizontal, 16)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.quickPhrases) { phrase in
                        Button(action: {
                            appState.inputText += phrase.content
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phrase.label)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                Text(phrase.content)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 4)
        }
    }
}
