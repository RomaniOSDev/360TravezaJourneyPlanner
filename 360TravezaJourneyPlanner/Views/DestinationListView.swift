import SwiftUI

struct DestinationListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var editorItem: Destination?
    @State private var showEditor = false
    @State private var query = ""
    @State private var filter: TripFilter = .active

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PhotoBanner(name: "banner_pass")
                    TextField("Search places, people, notes", text: $query)
                        .padding(12)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundColor(.white)

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if let next = store.nextTrip(), filter == .active {
                            countdownCard(next)
                        }
                        Text(listTitle)
                            .font(.system(.title, design: .serif).weight(.bold))
                            .foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TripFilter.allCases) { item in
                                    FilterChip(title: item.rawValue, selected: filter == item) {
                                        filter = item
                                    }
                                }
                            }
                        }
                        destinationStack
                    } else {
                        Text("Search")
                            .font(.system(.title, design: .serif).weight(.bold))
                            .foregroundColor(.white)
                        searchStack
                    }
                }
                .padding(18)
            }
            .canvasBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Destinations")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 14) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(Color("AppAccent"))
                        }
                        NavigationLink {
                            StatisticsView()
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundColor(Color("AppAccent"))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        NavigationLink {
                            PackingBoardView()
                        } label: {
                            Image(systemName: "suitcase.fill")
                                .foregroundColor(Color("AppAccent"))
                        }
                        NavigationLink {
                            CulturalLogView()
                        } label: {
                            Image(systemName: "globe.europe.africa.fill")
                                .foregroundColor(Color("AppAccent"))
                        }
                        Button {
                            editorItem = nil
                            showEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(Color("AppAccent"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                DestinationEditorView(existing: editorItem)
            }
            .onAppear {
                TripReminders.requestAccess()
                TripReminders.resync(destinations: store.destinations, packing: store.packingItems)
            }
        }
    }

    private var listTitle: String {
        switch filter {
        case .active: return "Your places"
        case .archive: return "Archive"
        default: return "\(filter.rawValue) places"
        }
    }

    @ViewBuilder
    private var destinationStack: some View {
        let items = store.visibleDestinations(filter: filter)
        if store.destinations.isEmpty {
            EmptyStateView(
                symbol: "list.bullet.rectangle",
                title: "No destinations yet",
                detail: "Tap + to start exploring. Link people, packing, and local notes to each place."
            )
        } else if items.isEmpty {
            EmptyStateView(
                symbol: "tray",
                title: "Nothing in this list",
                detail: filter == .archive ? "Archived trips will appear here." : "Try another status, or add a destination."
            )
        } else {
            ForEach(items) { item in
                NavigationLink {
                    DestinationDetailView(destination: item)
                } label: {
                    destinationCard(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var searchStack: some View {
        let hits = store.search(query)
        if hits.isEmpty {
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "No matches",
                detail: "Try a place name, a person, or a word from a note."
            )
        } else {
            ForEach(hits) { hit in
                NavigationLink {
                    DestinationDetailView(destination: hit.destination)
                } label: {
                    TicketCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(hit.kind.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundColor(Color("AppAccent"))
                            Text(hit.destination.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(hit.detail)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.72))
                                .lineLimit(3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func countdownCard(_ item: Destination) -> some View {
        NavigationLink {
            DestinationDetailView(destination: item)
        } label: {
            TicketCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.status == .current ? "Happening now" : "Next up")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppAccent"))
                    Text(item.name)
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundColor(.white)
                    Text(countdownLabel(for: item))
                        .foregroundColor(.white.opacity(0.85))
                    let unpacked = store.unpackedCount(for: item.id)
                    Text(unpacked == 0 ? "Kit is ready" : "\(unpacked) kit items still open")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppAccent"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func destinationCard(_ item: Destination) -> some View {
        TicketCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(item.region)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.72))
                    Text(item.visitDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("AppAccent"))
                    Text(item.isArchived ? "Archive" : item.status.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label("\(store.contacts(for: item.id).count)", systemImage: "person.2")
                    Label("\(store.packing(for: item.id).count)", systemImage: "suitcase")
                    Label("\(store.notes(for: item.id).count)", systemImage: "text.book.closed")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func countdownLabel(for item: Destination) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: item.visitDate)
        ).day ?? 0
        if days <= 0 { return "Today · \(item.visitDate.formatted(date: .long, time: .omitted))" }
        if days == 1 { return "Tomorrow · \(item.visitDate.formatted(date: .abbreviated, time: .omitted))" }
        return "In \(days) days · \(item.visitDate.formatted(date: .abbreviated, time: .omitted))"
    }
}

struct DestinationEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: Destination?

    @State private var name = ""
    @State private var region = ""
    @State private var visitDate = Date()
    @State private var status: TripStatus = .upcoming
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("City or region", text: $name)
                    TextField("Country or area", text: $region)
                    DatePicker("Visit date", selection: $visitDate, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        ForEach(TripStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existing == nil ? "New destination" : "Edit destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    region = existing.region
                    visitDate = existing.visitDate
                    status = existing.status
                } else {
                    status = TripStatus.inferred(from: visitDate)
                }
            }
        }
        .canvasBackground()
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRegion = region.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            error = "Add a destination name."
            return
        }
        if trimmedRegion.isEmpty {
            error = "Add a region or country."
            return
        }
        let item = Destination(
            id: existing?.id ?? UUID(),
            name: trimmedName,
            visitDate: visitDate,
            region: trimmedRegion,
            status: status,
            isArchived: existing?.isArchived ?? false,
            spendLimit: existing?.spendLimit ?? 0
        )
        store.upsertDestination(item)
        Haptics.success()
        dismiss()
    }
}
