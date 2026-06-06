import SwiftUI

struct MessageBubble: View {
    let message: Message
    @State private var appeared = false

    var body: some View {
        if message.type == .system {
            systemBubble
        } else {
            userBubble
        }
    }

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

    private var userBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 48)

            VStack(alignment: .trailing, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.blue.opacity(0.15), in: .rect(cornerRadius: 18))
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                HStack(spacing: 3) {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                    statusIcon
                }
                .padding(.trailing, 4)
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
    }

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

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: message.timestamp)
    }
}
