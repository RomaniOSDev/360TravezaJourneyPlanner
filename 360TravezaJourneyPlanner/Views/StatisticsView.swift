import Charts
import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoBanner(name: "banner_pass")
                Text("Trip statistics")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                Text("A snapshot of destinations, kits, people, and notes.")
                    .foregroundColor(.white.opacity(0.75))

                if store.destinations.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "Nothing to chart yet",
                        detail: "Add a destination, then packing and notes will appear as graphs here."
                    )
                } else {
                    summaryGrid
                    tripsChartCard
                    if !store.packingItems.isEmpty {
                        packingCategoryChartCard
                        packingProgressChartCard
                    }
                    if !store.culturalNotes.isEmpty {
                        notesChartCard
                    }
                    if !store.expenses.isEmpty {
                        spendChartCard
                    }
                }
            }
            .padding(18)
        }
        .canvasBackground()
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryTile(title: "Places", value: "\(store.destinations.count)", symbol: "mappin.and.ellipse")
            summaryTile(title: "Contacts", value: "\(store.contacts.count)", symbol: "person.2.fill")
            summaryTile(title: "Kit items", value: "\(store.packingItems.count)", symbol: "suitcase.fill")
            summaryTile(title: "Packed", value: packedRatioLabel, symbol: "checkmark.circle.fill")
        }
    }

    private func summaryTile(title: String, value: String, symbol: String) -> some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .foregroundColor(Color("AppAccent"))
                Text(value)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var tripsChartCard: some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Visits by month")
                    .font(.headline)
                    .foregroundColor(.white)
                Chart(monthlyTrips) { row in
                    BarMark(
                        x: .value("Month", row.date, unit: .month),
                        y: .value("Trips", row.count)
                    )
                    .foregroundStyle(Color("AppAccent"))
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var packingCategoryChartCard: some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kit items by category")
                    .font(.headline)
                    .foregroundColor(.white)
                Chart(categoryStats) { row in
                    BarMark(
                        x: .value("Items", row.total),
                        y: .value("Category", row.name)
                    )
                    .foregroundStyle(by: .value("Category", row.name))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale([
                    PackingCategory.clothing.rawValue: Color("AppAccent"),
                    PackingCategory.tech.rawValue: Color("AppPrimary"),
                    PackingCategory.essentials.rawValue: Color.white.opacity(0.75)
                ])
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(height: CGFloat(max(categoryStats.count, 1) * 44 + 24))
            }
        }
    }

    private var packingProgressChartCard: some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Packed vs remaining")
                    .font(.headline)
                    .foregroundColor(.white)
                Chart {
                    ForEach(placePacking) { place in
                        BarMark(
                            x: .value("Count", place.packed),
                            y: .value("Place", place.name)
                        )
                        .foregroundStyle(by: .value("Status", "Packed"))
                        BarMark(
                            x: .value("Count", place.remaining),
                            y: .value("Place", place.name)
                        )
                        .foregroundStyle(by: .value("Status", "Left"))
                    }
                }
                .chartForegroundStyleScale([
                    "Packed": Color("AppAccent"),
                    "Left": Color.white.opacity(0.28)
                ])
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(height: CGFloat(max(placePacking.count, 1) * 44 + 48))
            }
        }
    }

    private var notesChartCard: some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cultural notes per place")
                    .font(.headline)
                    .foregroundColor(.white)
                Chart(notesByPlace) { row in
                    BarMark(
                        x: .value("Place", row.name),
                        y: .value("Notes", row.count)
                    )
                    .foregroundStyle(Color("AppPrimary"))
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var spendChartCard: some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Logged spend by place")
                    .font(.headline)
                    .foregroundColor(.white)
                Chart(spendByPlace) { row in
                    BarMark(
                        x: .value("Place", row.name),
                        y: .value("Logged", row.total)
                    )
                    .foregroundStyle(Color("AppAccent"))
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var packedRatioLabel: String {
        let total = store.packingItems.count
        guard total > 0 else { return "0%" }
        let packed = store.packingItems.filter(\.isPacked).count
        return "\(Int((Double(packed) / Double(total) * 100).rounded()))%"
    }

    private var monthlyTrips: [MonthPoint] {
        let calendar = Calendar.current
        let now = Date()
        guard let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let start = calendar.date(byAdding: .month, value: -11, to: startMonth) else { return [] }
        var counts: [Date: Int] = [:]
        for offset in 0..<12 {
            if let month = calendar.date(byAdding: .month, value: offset, to: start) {
                counts[month] = 0
            }
        }
        for destination in store.destinations {
            let month = calendar.date(from: calendar.dateComponents([.year, .month], from: destination.visitDate)) ?? destination.visitDate
            if counts[month] != nil {
                counts[month, default: 0] += 1
            }
        }
        return counts.keys.sorted().map { MonthPoint(date: $0, count: counts[$0] ?? 0) }
    }

    private var categoryStats: [CategoryPoint] {
        PackingCategory.allCases.compactMap { category in
            let items = store.packingItems.filter { $0.category == category.rawValue }
            guard !items.isEmpty else { return nil }
            return CategoryPoint(name: category.rawValue, total: items.count)
        }
    }

    private var placePacking: [PlacePackingPoint] {
        store.destinations.compactMap { place in
            let items = store.packing(for: place.id)
            guard !items.isEmpty else { return nil }
            let packed = items.filter(\.isPacked).count
            return PlacePackingPoint(id: place.id, name: place.name, packed: packed, remaining: items.count - packed)
        }
    }

    private var notesByPlace: [NotePoint] {
        store.destinations.compactMap { place in
            let count = store.notes(for: place.id).count
            guard count > 0 else { return nil }
            return NotePoint(id: place.id, name: place.name, count: count)
        }
    }

    private var spendByPlace: [SpendPoint] {
        store.destinations.compactMap { place in
            let total = store.spent(for: place.id)
            guard total > 0 else { return nil }
            return SpendPoint(id: place.id, name: place.name, total: total)
        }
    }
}

private struct MonthPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

private struct CategoryPoint: Identifiable {
    var id: String { name }
    let name: String
    let total: Int
}

private struct PlacePackingPoint: Identifiable {
    let id: UUID
    let name: String
    let packed: Int
    let remaining: Int
}

private struct NotePoint: Identifiable {
    let id: UUID
    let name: String
    let count: Int
}

private struct SpendPoint: Identifiable {
    let id: UUID
    let name: String
    let total: Double
}
