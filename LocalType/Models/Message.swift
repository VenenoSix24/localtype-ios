import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case acked
    case error
}

enum MessageType: String, Codable {
    case user
    case system
}

struct Message: Identifiable, Codable {
    let id: String
    let text: String
    let timestamp: Date
    let type: MessageType
    var status: MessageStatus

    init(id: String = UUID().uuidString, text: String, timestamp: Date = .now, type: MessageType = .user, status: MessageStatus = .sending) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.type = type
        self.status = status
    }
}
