import SwiftUI

struct PackingBoardView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoBanner(name: "tile_market")
                Text("Kits by destination")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                if store.destinations.isEmpty {
                    EmptyStateView(symbol: "suitcase.fill", title: "Prepare your travel kit", detail: "Add a destination first, then build a list from local hints.")
                } else {
                    ForEach(store.destinations.filter { !$0.isArchived }) { place in
                        let items = store.packing(for: place.id)
                        let packed = items.filter(\.isPacked).count
                        NavigationLink {
                            DestinationDetailView(destination: place)
                        } label: {
                            TicketCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(place.name).font(.headline).foregroundColor(.white)
                                    Text(items.isEmpty ? "No kit items yet" : "\(packed) of \(items.count) packed")
                                        .foregroundColor(Color("AppAccent"))
                                    if !items.isEmpty {
                                        ProgressView(value: Double(packed), total: Double(max(items.count, 1)))
                                            .tint(Color("AppPrimary"))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Templates")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundColor(.white)
                Text("Winter, Beach, and City break are ready to apply from a destination. Saved kits can be removed here.")
                    .foregroundColor(.white.opacity(0.75))
                ForEach(store.allTemplates) { template in
                    TicketCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.name).font(.headline).foregroundColor(.white)
                                Text("\(template.items.count) items")
                                    .foregroundColor(Color("AppAccent"))
                            }
                            Spacer()
                            if !KitLibrary.builtIn.contains(where: { $0.id == template.id }) {
                                Button(role: .destructive) {
                                    store.deleteTemplate(template)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white.opacity(0.55))
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .canvasBackground()
        .navigationTitle("Travel kit")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CulturalLogView: View {
    @EnvironmentObject private var store: DataStore
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoBanner(name: "tile_trail")
                Text("Local insights")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                TextField("Search notes", text: $query)
                    .padding(12)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.white)
                if store.culturalNotes.isEmpty {
                    EmptyStateView(
                        symbol: "globe.europe.africa.fill",
                        title: "Start by adding your first destination insights",
                        detail: "Open a destination and capture advice from people who live there."
                    )
                } else {
                    ForEach(store.destinations) { place in
                        let notes = filteredNotes(for: place)
                        if !notes.isEmpty {
                            Text(place.name)
                                .font(.headline)
                                .foregroundColor(Color("AppAccent"))
                            ForEach(notes) { note in
                                TicketCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(note.author).font(.caption.weight(.semibold)).foregroundColor(.white.opacity(0.7))
                                        Text(note.text).foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .canvasBackground()
        .navigationTitle("Cultural notes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filteredNotes(for place: Destination) -> [CulturalNote] {
        let notes = store.notes(for: place.id)
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return notes }
        return notes.filter {
            $0.text.localizedCaseInsensitiveContains(needle) || $0.author.localizedCaseInsensitiveContains(needle)
        }
    }
}
