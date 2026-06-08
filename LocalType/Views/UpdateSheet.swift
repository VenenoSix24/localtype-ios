import SwiftUI

struct UpdateSheet: View {
    @Environment(AppState.self) private var appState
    let info: UpdateInfo
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(appState.accentColor.color)
                Text("发现新版本 v\(info.latestVersion)")
                    .font(.title3.weight(.semibold))
                Text("当前版本 v\(info.currentVersion)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 28)

            // Release notes
            if !info.releaseNotes.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("更新内容")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                        Text(info.releaseNotes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(16)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 14))
            }

            // Buttons
            HStack(spacing: 12) {
                Button {
                    appState.skipCurrentUpdate()
                    isPresented = false
                } label: {
                    Text("跳过此版本")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 18))
                        .foregroundStyle(Color(.label))
                }

                Button {
                    if let url = URL(string: info.repoUrl) {
                        UIApplication.shared.open(url)
                    }
                    isPresented = false
                } label: {
                    Text("立即更新")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(appState.accentColor.color, in: .rect(cornerRadius: 18))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
