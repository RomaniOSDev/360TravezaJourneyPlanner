import Foundation

enum TripStatus: String, CaseIterable, Codable {
    case upcoming = "Upcoming"
    case current = "Current"
    case done = "Done"

    static func inferred(from date: Date, now: Date = Date()) -> TripStatus {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let visit = calendar.startOfDay(for: date)
        if visit == today { return .current }
        if visit > today { return .upcoming }
        return .done
    }
}

enum TripFilter: String, CaseIterable, Identifiable {
    case active = "All"
    case upcoming = "Upcoming"
    case current = "Current"
    case done = "Done"
    case archive = "Archive"

    var id: String { rawValue }
}

struct Destination: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var visitDate: Date
    var region: String
    var status: TripStatus
    var isArchived: Bool
    var spendLimit: Double

    enum CodingKeys: String, CodingKey {
        case id, name, visitDate, region, status, isArchived, spendLimit
    }

    init(
        id: UUID = UUID(),
        name: String,
        visitDate: Date,
        region: String,
        status: TripStatus? = nil,
        isArchived: Bool = false,
        spendLimit: Double = 0
    ) {
        self.id = id
        self.name = name
        self.visitDate = visitDate
        self.region = region
        self.status = status ?? TripStatus.inferred(from: visitDate)
        self.isArchived = isArchived
        self.spendLimit = spendLimit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        visitDate = try container.decode(Date.self, forKey: .visitDate)
        region = try container.decode(String.self, forKey: .region)
        status = try container.decodeIfPresent(TripStatus.self, forKey: .status) ?? TripStatus.inferred(from: visitDate)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        spendLimit = try container.decodeIfPresent(Double.self, forKey: .spendLimit) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(visitDate, forKey: .visitDate)
        try container.encode(region, forKey: .region)
        try container.encode(status, forKey: .status)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(spendLimit, forKey: .spendLimit)
    }
}

struct ContactInfo: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var name: String
    var phone: String
    var email: String
    var packingHint: String

    init(id: UUID = UUID(), destinationId: UUID, name: String, phone: String, email: String, packingHint: String) {
        self.id = id
        self.destinationId = destinationId
        self.name = name
        self.phone = phone
        self.email = email
        self.packingHint = packingHint
    }
}

struct PackingItem: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var title: String
    var category: String
    var isPacked: Bool
    var suggestedBy: String
    var carriedBy: String

    enum CodingKeys: String, CodingKey {
        case id, destinationId, title, category, isPacked, suggestedBy, carriedBy
    }

    init(
        id: UUID = UUID(),
        destinationId: UUID,
        title: String,
        category: String,
        isPacked: Bool,
        suggestedBy: String,
        carriedBy: String = ""
    ) {
        self.id = id
        self.destinationId = destinationId
        self.title = title
        self.category = category
        self.isPacked = isPacked
        self.suggestedBy = suggestedBy
        self.carriedBy = carriedBy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        destinationId = try container.decode(UUID.self, forKey: .destinationId)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        isPacked = try container.decode(Bool.self, forKey: .isPacked)
        suggestedBy = try container.decode(String.self, forKey: .suggestedBy)
        carriedBy = try container.decodeIfPresent(String.self, forKey: .carriedBy) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(destinationId, forKey: .destinationId)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(isPacked, forKey: .isPacked)
        try container.encode(suggestedBy, forKey: .suggestedBy)
        try container.encode(carriedBy, forKey: .carriedBy)
    }
}

struct CulturalNote: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var author: String
    var text: String
    var updatedAt: Date

    init(id: UUID = UUID(), destinationId: UUID, author: String, text: String, updatedAt: Date = Date()) {
        self.id = id
        self.destinationId = destinationId
        self.author = author
        self.text = text
        self.updatedAt = updatedAt
    }
}

struct TripExpense: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var title: String
    var amount: Double

    init(id: UUID = UUID(), destinationId: UUID, title: String, amount: Double) {
        self.id = id
        self.destinationId = destinationId
        self.title = title
        self.amount = amount
    }
}

struct KitTemplateItem: Codable, Equatable {
    var title: String
    var category: String
}

struct KitTemplate: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var items: [KitTemplateItem]

    init(id: UUID = UUID(), name: String, items: [KitTemplateItem]) {
        self.id = id
        self.name = name
        self.items = items
    }
}

struct SearchHit: Identifiable {
    let id: UUID
    let destination: Destination
    let kind: String
    let detail: String
}

enum PackingCategory: String, CaseIterable {
    case clothing = "Clothing"
    case tech = "Tech"
    case essentials = "Essentials"
}
