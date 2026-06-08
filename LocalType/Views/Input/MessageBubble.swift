import SwiftUI

struct MessageBubble: View {
    @Environment(AppState.self) private var appState
    let message: Message
    @State private var appeared = false

    var body: some View {
        if message.type == .system {
            systemBubble
        } else {
            switch appState.bubbleStyle {
            case .liquidGlass:
                liquidGlassBubble
            case .classic:
                classicBubble
            case .minimal:
                minimalBubble
            }
        }
    }

    // MARK: - System Bubble

    private var systemBubble: some View {
        Text(message.text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8, anchor: .center)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
    }

    // MARK: - Liquid Glass (default)

    private var liquidGlassBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 48)

            VStack(alignment: .trailing, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(appState.accentColor.color.opacity(0.15), in: .rect(cornerRadius: 18))
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                metadataRow(foreground: .secondary)
            }
        }
        .padding(.vertical, 1)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .contextMenu {
            contextMenuContent
        } preview: {
            bubblePreview
        }
    }

    // MARK: - Classic (iMessage style)

    private var classicBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 48)

            VStack(alignment: .trailing, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(appState.accentColor.color, in: .rect(cornerRadius: 18))

                metadataRow(foreground: .tertiary)
            }
        }
        .padding(.vertical, 1)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .contextMenu {
            contextMenuContent
        } preview: {
            bubblePreview
        }
    }

    // MARK: - Minimal

    private var minimalBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(appState.accentColor.color)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    statusIcon
                }
            }

            Spacer(minLength: 48)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .contextMenu {
            contextMenuContent
        } preview: {
            bubblePreview
        }
    }

    // MARK: - Bubble Preview (for context menu)

    private var bubblePreview: some View {
        Text(message.text)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .lineLimit(1)
            .frame(maxWidth: 260, alignment: .trailing)
            .background(appState.accentColor.color.opacity(0.15), in: .rect(cornerRadius: 18))
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .padding(4)
    }

    // MARK: - Metadata Row

    private func metadataRow<S: ShapeStyle>(foreground: S) -> some View {
        HStack(spacing: 3) {
            Text(timeString)
                .font(.caption2)
                .foregroundStyle(foreground)
            statusIcon
        }
        .padding(.trailing, 4)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        case .acked:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            UIPasteboard.general.string = message.text
        } label: {
            Label("复制", systemImage: "doc.on.doc")
        }

        Button {
            appState.inputText = message.text
        } label: {
            Label("再次编辑", systemImage: "pencil")
        }

        Button {
            appState.inputText = message.text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appState.sendText()
            }
        } label: {
            Label("再次发送", systemImage: "arrow.up.circle")
        }
    }

    // MARK: - Helpers

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: message.timestamp)
    }
}
