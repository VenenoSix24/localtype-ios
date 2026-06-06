import Foundation

struct DiscoveredDevice: Identifiable, Codable, Equatable, Hashable {
    let id: String  // serverId
    var name: String
    var ip: String
    var os: String?
    var alias: String?
    var discoveredAt: Date
    var isOnline: Bool = true

    var displayName: String { alias ?? name }
}
