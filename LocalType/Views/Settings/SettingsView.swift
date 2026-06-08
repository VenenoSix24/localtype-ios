import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var editingName = false
    @State private var nameText = ""
    @State private var showBubbleSheet = false

    private let themes = [
        ("system", "跟随系统", "circle.lefthalf.filled"),
        ("light", "浅色", "sun.max.fill"),
        ("dark", "深色", "moon.fill")
    ]

    var body: some View {
        @Bindable var state = appState
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
                    HapticManager.impact(.light)
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
                        HapticManager.selection()
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

                // Bubble Style
                Button {
                    HapticManager.impact(.light)
                    showBubbleSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("聊天气泡")
                        Spacer()
                        Text(appState.bubbleStyle.name)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.quaternary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .confirmationDialog("聊天气泡风格", isPresented: $showBubbleSheet, titleVisibility: .visible) {
                    ForEach(BubbleStyle.allCases) { style in
                        Button(style.name) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.bubbleStyle = style
                            }
                            HapticManager.selection()
                        }
                    }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("选择你喜欢的聊天气泡风格")
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
            }

            // MARK: - General
            Section("通用") {
                ForEach([("unicode", "Unicode 直接输入", "keyboard"), ("clipboard", "剪贴板粘贴", "doc.on.clipboard")], id: \.0) { method in
                    Button {
                        HapticManager.selection()
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

                Toggle(isOn: $state.autoJumpToInput) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("连接后跳转输入页")
                                .font(.body)
                            Text("连接成功后自动切换到输入页面")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .tint(appState.accentColor.color)
                .onChange(of: state.autoJumpToInput) { _, _ in HapticManager.selection() }

                Toggle(isOn: $state.hapticEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("触觉反馈")
                                .font(.body)
                            Text("操作时的振动反馈")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .tint(appState.accentColor.color)
                .onChange(of: state.hapticEnabled) { _, _ in HapticManager.selection() }
            }

            // MARK: - About
            Section {
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

                Button {
                    HapticManager.impact(.light)
                    UIApplication.shared.open(URL(string: "https://github.com/VenenoSix24/localtype")!)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("GitHub 仓库")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.impact(.light)
                    UIApplication.shared.open(URL(string: "https://github.com/VenenoSix24/localtype/issues")!)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.bubble")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("反馈问题")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.impact(.light)
                    UIApplication.shared.open(URL(string: "https://github.com/VenenoSix24")!)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)
                        Text("开发者")
                        Spacer()
                        Text("VenenoSix24")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } footer: {
                HStack(spacing: 4) {
                    Text("LocalType \(appState.currentVersion)")
                        .font(.caption2)
                        .foregroundStyle(Color(.systemGray))
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(appState.accentColor.color)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 16)
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
}
