import SwiftUI

enum Milestone: Int, CaseIterable, Comparable {
    case newbie = 0
    case beginner = 100
    case proficient = 1_000
    case skilled = 5_000
    case expert = 10_000
    case master = 50_000
    case legend = 100_000

    var threshold: Int { rawValue }

    var name: String {
        switch self {
        case .newbie:     return "键盘新手"
        case .beginner:   return "初窥门径"
        case .proficient: return "小有成就"
        case .skilled:    return "渐入佳境"
        case .expert:     return "炉火纯青"
        case .master:     return "登峰造极"
        case .legend:     return "键盘之神"
        }
    }

    var icon: String {
        switch self {
        case .newbie:     return "keyboard"
        case .beginner:   return "figure.walk"
        case .proficient: return "star.fill"
        case .skilled:    return "flame.fill"
        case .expert:     return "bolt.fill"
        case .master:     return "crown.fill"
        case .legend:     return "sparkles"
        }
    }

    static func < (lhs: Milestone, rhs: Milestone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
