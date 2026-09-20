import SwiftUI

struct BlendLibraryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showEditor = false
    @State private var editing: SpiceBlend?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Polaroid(image: "banner_herbs", tilt: -2)
                        .padding(.horizontal, 28)
                    Text("Spice shelf")
                        .font(.system(size: 34, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    if store.blends.isEmpty {
                        RecipeCard(title: "No blends yet", detail: "Mix two or more spices. The market list fills itself from the jar.")
                    } else {
                        ForEach(store.blends) { blend in
                            Button {
                                editing = blend
                                showEditor = true
                            } label: {
                                RecipeCard(title: blend.name, detail: names(for: blend.spiceIds).joined(separator: " · "))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete", role: .destructive) { store.deleteBlend(blend) }
                            }
                        }
                    }
                    StampButton(title: "New blend") {
                        editing = nil
                        showEditor = true
                    }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditor, onDismiss: { editing = nil }) {
                BlendEditorView(existing: editing)
            }
        }
    }

    private func names(for ids: [String]) -> [String] {
        ids.compactMap { id in SpiceCatalog.all.first(where: { $0.id == id })?.name }
    }
}

struct BlendEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: SpiceBlend?
    @State private var name = ""
    @State private var selected: Set<String> = []
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Blend name", text: $name)
                Section("Spices") {
                    ForEach(SpiceCatalog.all) { spice in
                        Button {
                            if selected.contains(spice.id) { selected.remove(spice.id) } else { selected.insert(spice.id) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(spice.name).foregroundColor(.primary)
                                    Text(spice.note).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if selected.contains(spice.id) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color("AppPrimary"))
                                }
                            }
                        }
                    }
                }
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .navigationTitle(existing == nil ? "Craft blend" : "Edit blend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    selected = Set(existing.spiceIds)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { error = "Name the blend."; return }
        if selected.count < 2 { error = "Pick at least two spices."; return }
        store.upsertBlend(SpiceBlend(id: existing?.id ?? UUID(), name: trimmed, spiceIds: Array(selected)))
        Haptics.success()
        dismiss()
    }
}

struct RecipeListView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Polaroid(image: "tile_pan", tilt: 3)
                        .padding(.horizontal, 28)
                    Text("Plates from your jars")
                        .font(.system(size: 30, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    if store.blends.isEmpty {
                        RecipeCard(title: "No recipes found", detail: "Create a blend to get started. Matching plates appear here.")
                    } else {
                        ForEach(store.blends) { blend in
                            let recipes = store.matchingRecipes(for: blend)
                            Text(blend.name)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            if recipes.isEmpty {
                                Text("No plate uses these spices yet.")
                                    .font(.system(.footnote, design: .serif))
                                    .foregroundColor(Color("AppPrimary").opacity(0.6))
                            }
                            ForEach(recipes) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeCard(title: recipe.title, detail: "\(recipe.minutes) min · \(recipe.summary)")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject private var store: DataStore
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Polaroid(image: "tile_mortar", tilt: -1)
                    .padding(.horizontal, 24)
                Text(recipe.title)
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text(recipe.summary)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                            .frame(width: 22)
                        Text(step)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color("AppPrimary").opacity(0.15)).frame(height: 1)
                    }
                }
                StampButton(title: store.favorites.contains(recipe.id) ? "Saved to favorites" : "Save plate") {
                    store.toggleFavorite(recipe.id)
                    Haptics.success()
                }
            }
            .padding(20)
        }
        .canvasBackground()
        .onAppear { store.markRecipeViewed(recipe.id) }
    }
}
