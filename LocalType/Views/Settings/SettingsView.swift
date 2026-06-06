import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var editingName = false
    @State private var nameText = ""

    private let themes = [
        ("system", "跟随系统", "circle.lefthalf.filled"),
        ("light", "浅色", "sun.max.fill"),
        ("dark", "深色", "moon.fill")
    ]

    var body: some View {
        List {
            // MARK: - Device Name
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "iphone")
                        .font(.title3)
                        .foregroundStyle(appState.accentColor.color)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("设备名称")
                            .font(.body)
                        Text(appState.deviceName)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.quaternary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    nameText = appState.deviceName
                    editingName = true
                }

                NavigationLink {
                    DeviceManagementView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "desktopcomputer")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("设备管理")
                        Spacer()
                        Text("\(appState.pairedDevices.count) 台")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }

                NavigationLink {
                    PhraseManagementView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("快捷短语")
                        Spacer()
                        Text("\(appState.quickPhrases.count) 条")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
            }

            // MARK: - Appearance
            Section("外观") {
                ForEach(themes, id: \.0) { theme in
                    Button {
                        appState.colorScheme = theme.0
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: theme.2)
                                .font(.title3)
                                .foregroundStyle(appState.accentColor.color)
                                .frame(width: 32)
                            Text(theme.1)
                                .foregroundStyle(.primary)
                            Spacer()
                            if appState.colorScheme == theme.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(appState.accentColor.color)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Theme Color
                VStack(alignment: .leading, spacing: 10) {
                    Text("主题色")
                        .font(.body)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(ThemeColor.allCases) { themeColor in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        appState.accentColor = themeColor
                                    }
                                    HapticManager.selection()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(themeColor.color.gradient)
                                            .frame(width: 36, height: 36)

                                        if appState.accentColor == themeColor {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2.5)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "checkmark")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Bubble Style
                VStack(alignment: .leading, spacing: 10) {
                    Text("聊天气泡")
                        .font(.body)
                    ForEach(BubbleStyle.allCases) { style in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.bubbleStyle = style
                            }
                            HapticManager.selection()
                        } label: {
                            HStack(spacing: 12) {
                                bubblePreview(for: style)
                                    .frame(width: 44, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(style.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(style.description)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if appState.bubbleStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(appState.accentColor.color)
                                }
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // MARK: - Injection Method
            Section("输入方式") {
                ForEach([("unicode", "Unicode 直接输入", "keyboard"), ("clipboard", "剪贴板粘贴", "doc.on.clipboard")], id: \.0) { method in
                    Button {
                        appState.injectionMethod = method.0
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: method.2)
                                .font(.title3)
                                .foregroundStyle(appState.accentColor.color)
                                .frame(width: 32)
                            Text(method.1)
                                .foregroundStyle(.primary)
                            Spacer()
                            if appState.injectionMethod == method.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(appState.accentColor.color)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: - Update
            Section("版本") {
                Button {
                    Task { await appState.checkForUpdate(silent: false) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("检查更新")
                        Spacer()
                        if appState.isCheckingUpdate {
                            ProgressView()
                        } else {
                            Text("v\(appState.currentVersion)")
                                .foregroundStyle(.secondary)
                                .monospaced()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(appState.isCheckingUpdate)

                if let info = appState.updateInfo, info.available {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("新版本 v\(info.latestVersion)")
                                .font(.body.weight(.medium))
                                .foregroundStyle(appState.accentColor.color)
                            Spacer()
                            Button("跳过") { appState.skipCurrentUpdate() }
                                .font(.caption)
                        }
                        if !info.releaseNotes.isEmpty {
                            Text(info.releaseNotes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // MARK: - About
            Section("关于") {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                    Text("LocalType")
                    Spacer()
                    Text("v\(appState.currentVersion)")
                        .foregroundStyle(.tertiary)
                        .monospaced()
                }
            }
        }
        .navigationTitle("设置")
        .alert("修改设备名称", isPresented: $editingName) {
            TextField("设备名称", text: $nameText)
            Button("取消", role: .cancel) {}
            Button("保存") {
                appState.deviceName = nameText
            }
        } message: {
            Text("当前名称：\(appState.deviceName)")
        }
    }

    // MARK: - Bubble Preview

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
