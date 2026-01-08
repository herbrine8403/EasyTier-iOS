import Foundation

struct TextItem: Identifiable, Equatable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
    let id = UUID()
    var text: String
    
    var description: String { text }
    
    enum CodingKeys: String, CodingKey {
        case text
    }
    
    init(_ text: String) {
        self.text = text
    }
    
    init(stringLiteral text: String) {
        self.text = text
    }
}
