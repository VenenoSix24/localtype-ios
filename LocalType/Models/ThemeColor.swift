import SwiftUI

enum ThemeColor: String, CaseIterable, Identifiable {
    case blue
    case indigo
    case purple
    case pink
    case red
    case orange
    case green
    case mint

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue:    return .blue
        case .indigo:  return .indigo
        case .purple:  return .purple
        case .pink:    return .pink
        case .red:     return .red
        case .orange:  return .orange
        case .green:   return .green
        case .mint:    return .mint
        }
    }

    var name: String {
        switch self {
        case .blue:    return "蓝色"
        case .indigo:  return "靛青"
        case .purple:  return "紫色"
        case .pink:    return "粉色"
        case .red:     return "红色"
        case .orange:  return "橙色"
        case .green:   return "绿色"
        case .mint:    return "薄荷"
        }
    }
}
