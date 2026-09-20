import Foundation

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class DataStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var destinations: [Destination]
    @Published var contacts: [ContactInfo]
    @Published var packingItems: [PackingItem]
    @Published var culturalNotes: [CulturalNote]
    @Published var templates: [KitTemplate]
    @Published var expenses: [TripExpense]

    private let defaults = UserDefaults.standard
    private enum Key {
        static let onboarding = "hasSeenOnboarding"
        static let destinations = "destinations"
        static let contacts = "contacts"
        static let packing = "packingLists"
        static let notes = "culturalNotes"
        static let templates = "kitTemplates"
        static let expenses = "tripExpenses"
    }

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Key.onboarding)
        destinations = Self.decode([Destination].self, key: Key.destinations)
        contacts = Self.decode([ContactInfo].self, key: Key.contacts)
        packingItems = Self.decode([PackingItem].self, key: Key.packing)
        culturalNotes = Self.decode([CulturalNote].self, key: Key.notes)
        templates = Self.decode([KitTemplate].self, key: Key.templates)
        expenses = Self.decode([TripExpense].self, key: Key.expenses)
        TripReminders.resync(destinations: destinations, packing: packingItems)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Key.onboarding)
    }

    func upsertDestination(_ item: Destination) {
        if let index = destinations.firstIndex(where: { $0.id == item.id }) {
            destinations[index] = item
        } else {
            destinations.append(item)
        }
        destinations.sort { $0.visitDate < $1.visitDate }
        persist(destinations, key: Key.destinations)
        refreshReminders()
    }

    func deleteDestination(_ item: Destination) {
        destinations.removeAll { $0.id == item.id }
        contacts.removeAll { $0.destinationId == item.id }
        packingItems.removeAll { $0.destinationId == item.id }
        culturalNotes.removeAll { $0.destinationId == item.id }
        expenses.removeAll { $0.destinationId == item.id }
        persist(destinations, key: Key.destinations)
        persist(contacts, key: Key.contacts)
        persist(packingItems, key: Key.packing)
        persist(culturalNotes, key: Key.notes)
        persist(expenses, key: Key.expenses)
        refreshReminders()
    }

    func upsertContact(_ item: ContactInfo) {
        if let index = contacts.firstIndex(where: { $0.id == item.id }) {
            contacts[index] = item
        } else {
            contacts.append(item)
        }
        persist(contacts, key: Key.contacts)
        let hint = item.packingHint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hint.isEmpty else { return }
        let exists = packingItems.contains {
            $0.destinationId == item.destinationId && $0.title.compare(hint, options: .caseInsensitive) == .orderedSame
        }
        if !exists {
            packingItems.append(
                PackingItem(
                    destinationId: item.destinationId,
                    title: hint,
                    category: PackingCategory.essentials.rawValue,
                    isPacked: false,
                    suggestedBy: item.name
                )
            )
            persist(packingItems, key: Key.packing)
            refreshReminders()
        }
    }

    func deleteContact(_ item: ContactInfo) {
        contacts.removeAll { $0.id == item.id }
        persist(contacts, key: Key.contacts)
    }

    func upsertPacking(_ item: PackingItem) {
        if let index = packingItems.firstIndex(where: { $0.id == item.id }) {
            packingItems[index] = item
        } else {
            packingItems.append(item)
        }
        persist(packingItems, key: Key.packing)
        refreshReminders()
    }

    func deletePacking(_ item: PackingItem) {
        packingItems.removeAll { $0.id == item.id }
        persist(packingItems, key: Key.packing)
        refreshReminders()
    }

    func upsertNote(_ item: CulturalNote) {
        if let index = culturalNotes.firstIndex(where: { $0.id == item.id }) {
            culturalNotes[index] = item
        } else {
            culturalNotes.append(item)
        }
        persist(culturalNotes, key: Key.notes)
    }

    func deleteNote(_ item: CulturalNote) {
        culturalNotes.removeAll { $0.id == item.id }
        persist(culturalNotes, key: Key.notes)
    }

    func upsertExpense(_ item: TripExpense) {
        if let index = expenses.firstIndex(where: { $0.id == item.id }) {
            expenses[index] = item
        } else {
            expenses.append(item)
        }
        persist(expenses, key: Key.expenses)
    }

    func deleteExpense(_ item: TripExpense) {
        expenses.removeAll { $0.id == item.id }
        persist(expenses, key: Key.expenses)
    }

    func saveTemplate(name: String, from destinationId: UUID) -> Bool {
        let items = packing(for: destinationId)
        guard !items.isEmpty else { return false }
        let template = KitTemplate(
            name: name,
            items: items.map { KitTemplateItem(title: $0.title, category: $0.category) }
        )
        templates.append(template)
        persist(templates, key: Key.templates)
        return true
    }

    func deleteTemplate(_ item: KitTemplate) {
        templates.removeAll { $0.id == item.id }
        persist(templates, key: Key.templates)
    }

    func applyTemplate(_ template: KitTemplate, to destinationId: UUID) -> Int {
        var added = 0
        let existing = packing(for: destinationId)
        for entry in template.items {
            let duplicate = existing.contains { $0.title.compare(entry.title, options: .caseInsensitive) == .orderedSame }
            guard !duplicate else { continue }
            packingItems.append(
                PackingItem(
                    destinationId: destinationId,
                    title: entry.title,
                    category: entry.category,
                    isPacked: false,
                    suggestedBy: template.name
                )
            )
            added += 1
        }
        if added > 0 {
            persist(packingItems, key: Key.packing)
            refreshReminders()
        }
        return added
    }

    func addSeasonHints(to destination: Destination) -> Int {
        let template = KitTemplate(name: "Season hint", items: SeasonalKit.suggestions(for: destination.visitDate))
        return applyTemplate(template, to: destination.id)
    }

    func addEtiquette(to destination: Destination) -> Int {
        var added = 0
        let existing = notes(for: destination.id)
        for card in EtiquetteNotes.cards(for: destination) {
            let duplicate = existing.contains { $0.text.compare(card.text, options: .caseInsensitive) == .orderedSame }
            guard !duplicate else { continue }
            culturalNotes.append(CulturalNote(destinationId: destination.id, author: card.author, text: card.text))
            added += 1
        }
        if added > 0 {
            persist(culturalNotes, key: Key.notes)
        }
        return added
    }

    func contacts(for destinationId: UUID) -> [ContactInfo] {
        contacts.filter { $0.destinationId == destinationId }
    }

    func packing(for destinationId: UUID) -> [PackingItem] {
        packingItems.filter { $0.destinationId == destinationId }
    }

    func notes(for destinationId: UUID) -> [CulturalNote] {
        culturalNotes.filter { $0.destinationId == destinationId }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func expenses(for destinationId: UUID) -> [TripExpense] {
        expenses.filter { $0.destinationId == destinationId }
    }

    func spent(for destinationId: UUID) -> Double {
        expenses(for: destinationId).reduce(0) { $0 + $1.amount }
    }

    func unpackedCount(for destinationId: UUID) -> Int {
        packing(for: destinationId).filter { !$0.isPacked }.count
    }

    func visibleDestinations(filter: TripFilter) -> [Destination] {
        switch filter {
        case .active:
            return destinations.filter { !$0.isArchived }
        case .upcoming:
            return destinations.filter { !$0.isArchived && $0.status == .upcoming }
        case .current:
            return destinations.filter { !$0.isArchived && $0.status == .current }
        case .done:
            return destinations.filter { !$0.isArchived && $0.status == .done }
        case .archive:
            return destinations.filter(\.isArchived)
        }
    }

    func nextTrip() -> Destination? {
        let open = destinations.filter { !$0.isArchived }
        if let current = open.first(where: { $0.status == .current }) {
            return current
        }
        let today = Calendar.current.startOfDay(for: Date())
        return open
            .filter { $0.status == .upcoming || Calendar.current.startOfDay(for: $0.visitDate) >= today }
            .sorted { $0.visitDate < $1.visitDate }
            .first
    }

    func search(_ raw: String) -> [SearchHit] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var hits: [SearchHit] = []
        for place in destinations {
            if place.name.localizedCaseInsensitiveContains(query) || place.region.localizedCaseInsensitiveContains(query) {
                hits.append(SearchHit(id: place.id, destination: place, kind: "Place", detail: place.region))
            }
            for person in contacts(for: place.id) where person.name.localizedCaseInsensitiveContains(query) {
                hits.append(SearchHit(id: person.id, destination: place, kind: "Person", detail: person.name))
            }
            for note in notes(for: place.id) where note.text.localizedCaseInsensitiveContains(query) || note.author.localizedCaseInsensitiveContains(query) {
                hits.append(SearchHit(id: note.id, destination: place, kind: "Note", detail: note.text))
            }
        }
        return hits
    }

    var allTemplates: [KitTemplate] {
        KitLibrary.builtIn + templates
    }

    func resetAllData() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        hasSeenOnboarding = false
        destinations = []
        contacts = []
        packingItems = []
        culturalNotes = []
        templates = []
        expenses = []
        TripReminders.cancelAll()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func refreshReminders() {
        TripReminders.resync(destinations: destinations, packing: packingItems)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T where T: RangeReplaceableCollection, T.Element: Decodable {
        guard let data = UserDefaults.standard.data(forKey: key), let value = try? JSONDecoder().decode(T.self, from: data) else {
            return T()
        }
        return value
    }
}
