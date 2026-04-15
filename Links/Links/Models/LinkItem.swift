import Foundation

struct LinkItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var value: String
    var kind: Kind
    var category: String

    enum Kind: String, Codable, CaseIterable {
        case link
        case file
    }

    init(id: UUID = UUID(), title: String, value: String, kind: Kind, category: String = "") {
        self.id = id
        self.title = title
        self.value = value
        self.kind = kind
        self.category = category
    }

    // Support decoding items saved before the category field existed
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        value = try container.decode(String.self, forKey: .value)
        kind = try container.decode(Kind.self, forKey: .kind)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    }
}
