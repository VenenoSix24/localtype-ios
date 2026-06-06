import Foundation

struct QuickPhrase: Identifiable, Codable, Equatable {
    let id: String
    var label: String
    var content: String

    init(id: String = UUID().uuidString, label: String, content: String) {
        self.id = id
        self.label = label
        self.content = content
    }
}
