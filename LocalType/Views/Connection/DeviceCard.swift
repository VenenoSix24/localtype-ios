import SwiftUI

struct DeviceCard: View {
    @Environment(AppState.self) private var appState
    let device: DiscoveredDevice
    let isConnected: Bool
    let isPaired: Bool
    let onTap: () -> Void
    let onRemove: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isConnected ? appState.accentColor.color.opacity(0.12) : Color(.tertiarySystemFill))
                        .frame(width: 44, height: 44)

                    Image(systemName: iconForOS)
                        .font(.system(size: 18))
                        .foregroundStyle(isConnected ? appState.accentColor.color : .secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(device.ip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospaced()

                        if let os = device.os {
                            Text(os.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.quaternary, in: .capsule)
                        }
                    }
                }

                Spacer()

                // Status
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(appState.accentColor.color)
                } else if isPaired {
                    Image(systemName: "wifi")
                        .font(.title3)
                        .foregroundStyle(device.isOnline ? appState.accentColor.color : Color(.tertiaryLabel))
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .contextMenu {
            if let onRemove, isPaired {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("移除设备", systemImage: "trash")
                }
            }
        }
    }

    private var iconForOS: String {
        switch device.os {
        case "macos": return "desktopcomputer"
        case "windows": return "pc"
        case "linux": return "terminal"
        default: return "display"
        }
    }
}
