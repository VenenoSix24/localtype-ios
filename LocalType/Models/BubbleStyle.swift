import Foundation

enum BubbleStyle: String, CaseIterable, Identifiable {
    case liquidGlass
    case classic
    case minimal

    var id: String { rawValue }

    var name: String {
        switch self {
        case .liquidGlass: return "液态玻璃"
        case .classic:     return "经典"
        case .minimal:     return "极简"
        }
    }

    var description: String {
        switch self {
        case .liquidGlass: return "iOS 26 液态玻璃风格"
        case .classic:     return "类似 iMessage 的实心气泡"
        case .minimal:     return "无背景，纯文字风格"
        }
    }
}
