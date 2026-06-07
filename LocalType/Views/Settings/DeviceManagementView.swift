import SwiftUI

struct DeviceManagementView: View {
    @Environment(AppState.self) private var appState
    @State private var editingDevice: DiscoveredDevice?
    @State private var aliasText: String = ""
    @State private var showUnpairConfirm: DiscoveredDevice?

    var body: some View {
        List {
            if appState.pairedDevices.isEmpty {
                ContentUnavailableView(
                    "没有已配对设备",
                    systemImage: "desktopcomputer",
                    description: Text("在「连接」页面扫描并配对设备")
                )
            } else {
                ForEach(appState.pairedDevices) { device in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 40, height: 40)
                            Image(systemName: iconForOS(device.os))
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.displayName)
                                .font(.body.weight(.medium))
                            HStack(spacing: 6) {
                                Text(device.ip)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospaced()
                                if let os = device.os {
                                    Text(os.uppercased())
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Spacer()

                        if device.alias != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundStyle(appState.accentColor.color)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        aliasText = device.alias ?? ""
                        editingDevice = device
                    }
                    .contextMenu {
                        Button {
                            aliasText = device.alias ?? ""
                            editingDevice = device
                        } label: {
                            Label("重命名", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showUnpairConfirm = device
                        } label: {
                            Label("取消配对", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            showUnpairConfirm = device
                        } label: {
                            Label("移除", systemImage: "trash")
                        }
                        .tint(.red)

                        Button {
                            aliasText = device.alias ?? ""
                            editingDevice = device
                        } label: {
                            Label("重命名", systemImage: "square.and.pencil")
                        }
                        .tint(.blue)
                    }
                    .confirmationDialog(
                        "确定要取消与「\(device.displayName)」的配对吗？",
                        isPresented: .init(
                            get: { showUnpairConfirm?.id == device.id },
                            set: { if !$0 { showUnpairConfirm = nil } }
                        ),
                        titleVisibility: .visible
                    ) {
                        Button("取消配对", role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                appState.removePairedDevice(id: device.id)
                            }
                            showUnpairConfirm = nil
                        }
                        Button("取消", role: .cancel) {
                            showUnpairConfirm = nil
                        }
                    } message: {
                        Text("取消后需要重新配对才能连接。")
                    }
                }
            }
        }
        .navigationTitle("设备管理")
        .alert("重命名设备", isPresented: .init(
            get: { editingDevice != nil },
            set: { if !$0 { editingDevice = nil } }
        )) {
            TextField("设备别名（留空恢复默认）", text: $aliasText)
            Button("取消", role: .cancel) { editingDevice = nil }
            Button("保存") {
                if let device = editingDevice {
                    appState.renamePairedDevice(id: device.id, alias: aliasText)
                }
                editingDevice = nil
            }
        } message: {
            if let device = editingDevice {
                Text("当前名称：\(device.name)")
            }
        }
    }

    private func iconForOS(_ os: String?) -> String {
        switch os {
        case "macos": return "desktopcomputer"
        case "windows": return "pc"
        case "linux": return "terminal"
        default: return "display"
        }
    }
}
