import UIKit

enum HapticManager {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "haptic_enabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "haptic_enabled")
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        notification(.success)
    }

    static func warning() {
        notification(.warning)
    }

    static func error() {
        notification(.error)
    }

    static func celebrate() {
        guard isEnabled else { return }
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            impact(.medium)
        }
    }
}
