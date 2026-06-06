import SwiftUI

struct StatisticsView: View {
    @Environment(AppState.self) private var appState
    @State private var cardsAppeared = false
    @State private var showAchievementSheet = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Level + Progress card (tappable)
                    Button {
                        showAchievementSheet = true
                        HapticManager.selection()
                    } label: {
                        levelCard
                    }
                    .buttonStyle(.plain)

                    // Streak banner
                    if appState.streakDays > 0 {
                        streakBanner
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 15)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.04), value: cardsAppeared)
                    }

                    // Total + Today row
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "sum",
                            iconColor: appState.accentColor.color,
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
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.08), value: cardsAppeared)

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
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.16), value: cardsAppeared)

                    // Fun facts
                    GlassCardSmall {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("趣味数据", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Divider()

                            FunFactRow(icon: "doc.text", text: "约可写 \(max(1, appState.totalChars / 500)) 篇 500 字短文", iconColor: appState.accentColor.color)
                            FunFactRow(icon: "message", text: "约可发送 \(max(1, appState.totalChars / 20)) 条消息", iconColor: appState.accentColor.color)
                            FunFactRow(icon: "clock", text: "按每分钟 40 字计算，已花费约 \(max(1, appState.totalChars / 40)) 分钟", iconColor: appState.accentColor.color)
                            if appState.totalChars > 0 {
                                FunFactRow(icon: "arrow.right.circle", text: "如果每公里跑 100 字，你已跑完 \(String(format: "%.1f", Double(appState.totalChars) / 100.0)) 公里", iconColor: appState.accentColor.color)
                            }
                        }
                    }
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.24), value: cardsAppeared)

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
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4).delay(0.32), value: cardsAppeared)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("统计")
            .onAppear {
                withAnimation {
                    cardsAppeared = true
                }
            }

            // Celebration overlay
            if appState.showingAchievement, let milestone = appState.newAchievement {
                CelebrationOverlay(
                    milestone: milestone,
                    accentColor: appState.accentColor.color
                ) {
                    appState.showingAchievement = false
                    appState.newAchievement = nil
                }
                .zIndex(1)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAchievementSheet) {
            AchievementSheet()
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        let current = appState.currentMilestone
        return GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 5)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: min(appState.milestoneProgress, 1.0))
                        .stroke(appState.accentColor.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: appState.milestoneProgress)
                    Image(systemName: current.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(appState.accentColor.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(current.name)
                            .font(.title3.weight(.bold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.quaternary)
                    }
                    if let next = appState.nextMilestone {
                        ProgressView(value: appState.milestoneProgress)
                            .tint(appState.accentColor.color)
                        Text("距「\(next.name)」还差 \(formatNumber(next.threshold - appState.totalChars)) 字符")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("已达最高等级 🎉")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0), value: cardsAppeared)
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack(spacing: 10) {
            Text("🔥")
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("连续输入 \(appState.streakDays) 天")
                    .font(.subheadline.weight(.semibold))
                Text(streakMessage)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(appState.accentColor.color.opacity(0.08), in: .rect(cornerRadius: 16))
    }

    private var streakMessage: String {
        let days = appState.streakDays
        if days >= 30 { return "太厉害了，坚持就是胜利！" }
        if days >= 7 { return "一周连续，习惯已养成！" }
        if days >= 3 { return "保持节奏，继续加油！" }
        return "每天输入，养成好习惯"
    }

    // MARK: - Helpers

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
    var iconColor: Color = .blue

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
