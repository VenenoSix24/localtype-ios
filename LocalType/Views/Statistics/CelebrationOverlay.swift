import SwiftUI

struct CelebrationOverlay: View {
    let milestone: Milestone
    let accentColor: Color
    @State private var appeared = false
    @State private var iconScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0
    @State private var opacity: Double = 0
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(appeared ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Celebration card
            VStack(spacing: 20) {
                // Animated icon with ring
                ZStack {
                    // Expanding ring
                    Circle()
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale)

                    // Icon background
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(iconScale)

                    // Icon
                    Image(systemName: milestone.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(accentColor)
                        .scaleEffect(iconScale)
                }

                VStack(spacing: 6) {
                    Text("等级提升！")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(milestone.name)
                        .font(.title.weight(.bold))

                    Text("已输入 \(formatNumber(milestone.threshold)) 字符")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
                iconScale = 1
                opacity = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                ringScale = 1.5
            }

            // Auto dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            appeared = false
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
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
