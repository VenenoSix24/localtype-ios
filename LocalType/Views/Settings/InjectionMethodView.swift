import SwiftUI

struct InjectionMethodView: View {
    @Environment(AppState.self) private var appState

    private let methods: [(String, String, String, String)] = [
        ("unicode", "Unicode 直接输入", "keyboard", "通过 Unicode 方式直接输入文本，兼容性最好"),
        ("clipboard", "剪贴板粘贴", "doc.on.clipboard", "通过剪贴板粘贴文本，速度更快但会覆盖剪贴板内容")
    ]

    var body: some View {
        List {
            ForEach(methods, id: \.0) { method in
                Button {
                    HapticManager.selection()
                    appState.injectionMethod = method.0
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: method.2)
                            .font(.title3)
                            .foregroundStyle(appState.accentColor.color)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(method.1)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(method.3)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

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
        .navigationTitle("输入方式")
    }
}
