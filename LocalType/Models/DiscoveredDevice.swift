import Foundation

struct DiscoveredDevice: Identifiable, Codable, Equatable, Hashable {
    let id: String  // serverId
    var name: String
    var ip: String
    var os: String?
    var alias: String?
    var discoveredAt: Date
    var isOnline: Bool = true

    var displayName: String {
        let base = alias ?? name
        if let range = base.range(of: " (") {
            return String(base[..<range.lowerBound])
        }
        if let range = base.range(of: "(") {
            return String(base[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return base
    }
}
