import SwiftUI

struct BubbleStyleView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(BubbleStyle.allCases) { style in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appState.bubbleStyle = style
                    }
                } label: {
                    HStack(spacing: 14) {
                        bubblePreview(for: style)
                            .frame(width: 48, height: 32)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(style.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(style.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if appState.bubbleStyle == style {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(appState.accentColor.color)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("聊天气泡")
    }

    @ViewBuilder
    private func bubblePreview(for style: BubbleStyle) -> some View {
        switch style {
        case .liquidGlass:
            RoundedRectangle(cornerRadius: 8)
                .fill(appState.accentColor.color.opacity(0.15))
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
        case .classic:
            RoundedRectangle(cornerRadius: 8)
                .fill(appState.accentColor.color)
        case .minimal:
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(appState.accentColor.color, lineWidth: 1.5)
        }
    }
}
