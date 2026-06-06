import SwiftUI

struct AchievementSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current level highlight
                    currentLevelCard

                    // Streak
                    if appState.streakDays > 0 {
                        streakBanner
                    }

                    // All milestones grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(Milestone.allCases, id: \.rawValue) { milestone in
                            milestoneCard(milestone)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("成就墙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Current Level Card

    private var currentLevelCard: some View {
        let current = appState.currentMilestone
        return GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(appState.accentColor.color.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: current.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(appState.accentColor.color)
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(current.name)
                        .font(.title3.weight(.bold))

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
        .padding(.horizontal, 16)
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack(spacing: 10) {
            Text("🔥")
                .font(.title2)
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
        .padding(.horizontal, 16)
    }

    private var streakMessage: String {
        let days = appState.streakDays
        if days >= 30 { return "太厉害了，坚持就是胜利！" }
        if days >= 7 { return "一周连续，习惯已养成！" }
        if days >= 3 { return "保持节奏，继续加油！" }
        return "每天输入，养成好习惯"
    }

    // MARK: - Milestone Card

    @ViewBuilder
    private func milestoneCard(_ milestone: Milestone) -> some View {
        let unlocked = appState.totalChars >= milestone.threshold
        let isCurrent = milestone == appState.currentMilestone

        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked
                        ? appState.accentColor.color.opacity(isCurrent ? 0.2 : 0.1)
                        : Color(.tertiarySystemFill))
                    .frame(width: 56, height: 56)

                if unlocked {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(appState.accentColor.color)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.quaternary)
                }
            }

            Text(milestone.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(unlocked ? .primary : .tertiary)

            if unlocked {
                Text("\(formatNumber(milestone.threshold)) 字符")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("还需 \(formatNumber(milestone.threshold - appState.totalChars))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(unlocked
                    ? appState.accentColor.color.opacity(0.04)
                    : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isCurrent ? appState.accentColor.color.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        )
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
