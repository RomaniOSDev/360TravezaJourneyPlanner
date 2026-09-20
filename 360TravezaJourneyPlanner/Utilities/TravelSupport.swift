import Foundation
import UserNotifications

enum AmountText {
    static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = value.rounded() == value ? 0 : 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func parse(_ raw: String) -> Double? {
        let filtered = raw.trimmingCharacters(in: .whitespacesAndNewlines).filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !filtered.isEmpty else { return nil }
        let normalized = filtered.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

enum TripReminders {
    static func requestAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func resync(destinations: [Destination], packing: [PackingItem]) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            center.removeAllPendingNotificationRequests()
            let calendar = Calendar.current
            for place in destinations where !place.isArchived && place.status != .done {
                let unpacked = packing.filter { $0.destinationId == place.id && !$0.isPacked }.count
                guard unpacked > 0 else { continue }
                guard let fireDay = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: place.visitDate)) else { continue }
                var parts = calendar.dateComponents([.year, .month, .day], from: fireDay)
                parts.hour = 10
                parts.minute = 0
                guard let fire = calendar.date(from: parts), fire > Date() else { continue }
                let content = UNMutableNotificationContent()
                content.title = place.name
                content.body = "3 days to go. \(unpacked) kit items still open."
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "kit-reminder-\(place.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

enum SeasonalKit {
    static func suggestions(for date: Date) -> [KitTemplateItem] {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 12, 1, 2:
            return [
                KitTemplateItem(title: "Warm layer", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Gloves", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Rain jacket", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Thermal socks", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Power adapter", category: PackingCategory.tech.rawValue)
            ]
        case 5, 6, 7, 8, 9:
            return [
                KitTemplateItem(title: "Sun hat", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Light shirt", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Sun protection", category: PackingCategory.essentials.rawValue),
                KitTemplateItem(title: "Reusable bottle", category: PackingCategory.essentials.rawValue),
                KitTemplateItem(title: "Insect protection", category: PackingCategory.essentials.rawValue)
            ]
        default:
            return [
                KitTemplateItem(title: "Light jacket", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Layered shirt", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Compact umbrella", category: PackingCategory.essentials.rawValue),
                KitTemplateItem(title: "Power adapter", category: PackingCategory.tech.rawValue)
            ]
        }
    }
}

enum KitLibrary {
    static let builtIn: [KitTemplate] = [
        KitTemplate(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-000000000001")!,
            name: "Winter",
            items: [
                KitTemplateItem(title: "Thermal layer", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Gloves", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Rain jacket", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Scarf", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Charger", category: PackingCategory.tech.rawValue)
            ]
        ),
        KitTemplate(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-000000000002")!,
            name: "Beach",
            items: [
                KitTemplateItem(title: "Swimwear", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Sun hat", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Sandals", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Sun protection", category: PackingCategory.essentials.rawValue),
                KitTemplateItem(title: "Dry bag", category: PackingCategory.essentials.rawValue)
            ]
        ),
        KitTemplate(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-000000000003")!,
            name: "City break",
            items: [
                KitTemplateItem(title: "Comfortable shoes", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Light jacket", category: PackingCategory.clothing.rawValue),
                KitTemplateItem(title: "Day bag", category: PackingCategory.essentials.rawValue),
                KitTemplateItem(title: "Power adapter", category: PackingCategory.tech.rawValue)
            ]
        )
    ]
}

enum EtiquetteNotes {
    static func cards(for destination: Destination) -> [(author: String, text: String)] {
        let haystack = "\(destination.name) \(destination.region)".lowercased()
        if haystack.contains("japan") {
            return [
                ("Local etiquette", "Remove shoes when entering homes and many traditional spaces."),
                ("Local etiquette", "Keep voices low on trains and queues, and stand on the marked side of escalators."),
                ("Local etiquette", "A small wrapped gift is a kind way to thank a host.")
            ]
        }
        if haystack.contains("thai") {
            return [
                ("Local etiquette", "Cover shoulders and knees at temples, and remove shoes before entering."),
                ("Local etiquette", "Avoid touching anyone's head, and point with an open hand rather than a finger.")
            ]
        }
        if haystack.contains("india") {
            return [
                ("Local etiquette", "Use the right hand for greetings and shared food."),
                ("Local etiquette", "Dress modestly at temples and family homes, and ask before photographing people.")
            ]
        }
        if haystack.contains("italy") || haystack.contains("italian") {
            return [
                ("Local etiquette", "Cover shoulders and knees in churches."),
                ("Local etiquette", "Greet staff when entering a shop or cafe, then make your request.")
            ]
        }
        if haystack.contains("france") || haystack.contains("french") {
            return [
                ("Local etiquette", "Start with a greeting before asking for help or placing an order."),
                ("Local etiquette", "Keep mealtime unhurried; lingering at the table is part of the visit.")
            ]
        }
        if haystack.contains("spain") || haystack.contains("spanish") {
            return [
                ("Local etiquette", "Evenings run late; dinner and plans often start later than you may expect."),
                ("Local etiquette", "Greet the room when you enter a small shop or family gathering.")
            ]
        }
        if haystack.contains("german") || haystack.contains("germany") {
            return [
                ("Local etiquette", "Be on time; arriving a few minutes early is noticed and appreciated."),
                ("Local etiquette", "Keep Sunday public spaces quieter, and recycle as labelled.")
            ]
        }
        if haystack.contains("united kingdom") || haystack.contains("england") || haystack.contains("britain") || haystack.contains("scotland") || haystack.contains("wales") {
            return [
                ("Local etiquette", "Queue in the order people arrived, and give a clear thank you."),
                ("Local etiquette", "Keep voices moderate on public transport.")
            ]
        }
        if haystack.contains("mexico") {
            return [
                ("Local etiquette", "A warm greeting comes before the request, even in busy shops."),
                ("Local etiquette", "Accept an offered snack or drink from a host before talking business.")
            ]
        }
        if haystack.contains("greece") || haystack.contains("greek") {
            return [
                ("Local etiquette", "Accept a welcome drink or snack from a host; declining too quickly can feel cold."),
                ("Local etiquette", "Dress modestly at monasteries and older churches.")
            ]
        }
        return [
            ("Local etiquette", "Learn a simple greeting in the local language before you arrive."),
            ("Local etiquette", "Ask before photographing people, homes, or ceremonies."),
            ("Local etiquette", "Follow the house rules your host shares, especially shoes and meal times.")
        ]
    }
}
