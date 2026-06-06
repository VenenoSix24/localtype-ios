import SwiftUI

struct StatisticsView: View {
    @Environment(AppState.self) private var appState

    private var level: (String, String, Int) {
        let chars = appState.totalChars
        if chars >= 100_000 { return ("键盘之神", "sparkles", 100_000) }
        if chars >= 50_000 { return ("登峰造极", "crown.fill", 50_000) }
        if chars >= 10_000 { return ("炉火纯青", "bolt.fill", 10_000) }
        if chars >= 5_000 { return ("渐入佳境", "flame.fill", 5_000) }
        if chars >= 1_000 { return ("小有成就", "star.fill", 1_000) }
        if chars >= 100 { return ("初窥门径", "figure.walk", 100) }
        return ("键盘新手", "keyboard", 0)
    }

    private var nextMilestone: (String, Int)? {
        let milestones: [(String, Int)] = [
            ("初窥门径", 100), ("小有成就", 1_000), ("渐入佳境", 5_000),
            ("炉火纯青", 10_000), ("登峰造极", 50_000), ("键盘之神", 100_000)
        ]
        return milestones.first { $0.1 > appState.totalChars }
    }

    private var progress: Double {
        guard let next = nextMilestone else { return 1.0 }
        let milestones = [100, 1_000, 5_000, 10_000, 50_000, 100_000]
        guard let idx = milestones.firstIndex(of: next.1), idx > 0 else {
            return Double(appState.totalChars) / Double(next.1)
        }
        let prev = milestones[idx - 1]
        let range = next.1 - prev
        let current = appState.totalChars - prev
        return Double(current) / Double(range)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Level + Progress card
                GlassCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color(.tertiarySystemFill), lineWidth: 5)
                                .frame(width: 64, height: 64)
                            Circle()
                                .trim(from: 0, to: min(progress, 1.0))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.6), value: progress)
                            Image(systemName: level.1)
                                .font(.system(size: 22))
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(level.0)
                                .font(.title3.weight(.bold))
                            if let next = nextMilestone {
                                ProgressView(value: progress)
                                    .tint(.blue)
                                Text("距「\(next.0)」还差 \(formatNumber(next.1 - appState.totalChars)) 字符")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("已达最高等级")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // Total + Today row
                HStack(spacing: 12) {
                    StatCard(
                        icon: "sum",
                        iconColor: .blue,
                        label: "总输入",
                        value: formatNumber(appState.totalChars),
                        unit: "字符"
                    )
                    StatCard(
                        icon: "textformat.abc",
                        iconColor: .orange,
                        label: "今日",
                        value: formatNumber(appState.todayChars),
                        unit: "字符"
                    )
                }

                // Daily avg + estimated reading
                HStack(spacing: 12) {
                    StatCard(
                        icon: "divide.circle",
                        iconColor: .purple,
                        label: "日均输入",
                        value: formatNumber(max(appState.totalChars / 30, appState.todayChars)),
                        unit: "字符"
                    )
                    StatCard(
                        icon: "book",
                        iconColor: .green,
                        label: "约等于",
                        value: String(format: "%.1f", Double(appState.totalChars) / 2500.0),
                        unit: "页书籍"
                    )
                }

                // Fun facts
                GlassCardSmall {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("趣味数据", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Divider()

                        FunFactRow(icon: "doc.text", text: "约可写 \(max(1, appState.totalChars / 500)) 篇 500 字短文")
                        FunFactRow(icon: "message", text: "约可发送 \(max(1, appState.totalChars / 20)) 条消息")
                        FunFactRow(icon: "clock", text: "按每分钟 40 字计算，已花费约 \(max(1, appState.totalChars / 40)) 分钟")
                        if appState.totalChars > 0 {
                            FunFactRow(icon: "arrow.right.circle", text: "如果每公里跑 100 字，你已跑完 \(String(format: "%.1f", Double(appState.totalChars) / 100.0)) 公里")
                        }
                    }
                }

                // Privacy
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("所有数据仅保存在本地，不会上传")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("统计")
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10_000 {
            return String(format: "%.1f万", Double(n) / 10_000.0)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        GlassCardSmall {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospaced()
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FunFactRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
