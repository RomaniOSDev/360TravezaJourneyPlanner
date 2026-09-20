import SwiftUI

struct NotesGalleryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showEditor = false
    @State private var editing: DesignNote?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Room notes")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                if store.notes.isEmpty {
                    Text("Capture your style inspirations")
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                    Text("Add a room note, then write captions and pin a look from Discover.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.6))
                        .padding(.top, 6)
                        .padding(.bottom, 16)
                } else {
                    ForEach(store.notes) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.room.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .tracking(1.4)
                                    .foregroundColor(Color("AppAccent"))
                                Text(note.title)
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(Color("AppPrimary"))
                                Text(note.description)
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(Color("AppPrimary").opacity(0.65))
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                }
                SlabButton(title: "New room note") {
                    editing = nil
                    showEditor = true
                }
                .padding(.top, 18)
            }
            .padding(22)
        }
        .canvasBackground()
        .sheet(isPresented: $showEditor) {
            NoteEditorView(existing: editing)
        }
    }
}

struct NoteDetailView: View {
    @EnvironmentObject private var store: DataStore
    let note: DesignNote
    @State private var showEdit = false
    @State private var captionText = ""
    @State private var error = ""
    @State private var confirmDelete = false

    private var live: DesignNote {
        store.notes.first(where: { $0.id == note.id }) ?? note
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Cutline(image: "tile_palette", height: 132, caption: "Material study")
                Text(live.room.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.6)
                    .foregroundColor(Color("AppAccent"))
                Text(live.title)
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text(live.description)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                DoubleRule()
                Text("Captions")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
                let items = store.captions(for: live.id)
                if items.isEmpty {
                    Text("No captions yet. Start by selecting a room photo to annotate.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.text)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            Text(item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(Color("AppPrimary").opacity(0.45))
                        }
                        .padding(.vertical, 8)
                        Hairline()
                    }
                }
                TextField("Add a caption", text: $captionText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(10)
                    .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                SlabButton(title: "Save caption", action: saveCaption)
            }
            .padding(22)
        }
        .canvasBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit note") { showEdit = true }
                    Button("Delete note", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            NoteEditorView(existing: live)
        }
        .confirmationDialog("Remove this room and its captions?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteNote(live) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func saveCaption() {
        let text = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { error = "Write a caption before saving."; return }
        error = ""
        store.upsertCaption(RoomCaption(noteId: live.id, text: text))
        captionText = ""
        Haptics.success()
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: DesignNote?
    @State private var title = ""
    @State private var room = ""
    @State private var icon = RoomIcon.sofa.rawValue
    @State private var description = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Room or style", text: $room)
                Picker("Icon", selection: $icon) {
                    ForEach(RoomIcon.allCases, id: \.rawValue) { item in
                        Label(item.rawValue, systemImage: item.rawValue).tag(item.rawValue)
                    }
                }
                TextField("Furnishings and layout", text: $description, axis: .vertical)
                    .lineLimit(4...8)
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .navigationTitle(existing == nil ? "New note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    title = existing.title
                    room = existing.room
                    icon = existing.icon
                    description = existing.description
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = room.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || r.isEmpty || d.isEmpty {
            error = "Fill title, room, and description."
            return
        }
        store.upsertNote(DesignNote(id: existing?.id ?? UUID(), title: t, icon: icon, room: r, description: d))
        Haptics.success()
        dismiss()
    }
}

struct CaptionStudioView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Captions")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                Cutline(image: "tile_palette", height: 110, caption: "Swatches on the sample table")
                    .padding(.bottom, 12)
                if store.captions.isEmpty {
                    Text("No captions yet. Start by selecting a room photo to annotate.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.55))
                } else {
                    ForEach(store.notes) { note in
                        let items = store.captions(for: note.id)
                        if !items.isEmpty {
                            Text(note.title.uppercased())
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .tracking(1.4)
                                .foregroundColor(Color("AppAccent"))
                                .padding(.top, 12)
                            ForEach(items) { item in
                                Text(item.text)
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(Color("AppPrimary"))
                                    .padding(.vertical, 8)
                                Hairline()
                            }
                        }
                    }
                }
            }
            .padding(22)
        }
        .canvasBackground()
    }
}

struct InspirationView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Discover")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Hairline()
                    .padding(.vertical, 10)
                if InspirationCatalog.all.isEmpty {
                    Text("Explore stunning room inspirations!")
                        .font(.system(.body, design: .serif))
                }
                ForEach(InspirationCatalog.all) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Cutline(image: item.image, height: 176, caption: item.style)
                        Text(item.title)
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                        Text(item.detail)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color("AppPrimary").opacity(0.7))
                        SlabButton(
                            title: store.favorites.contains(item.id) ? "Pinned to project" : "Pin to project",
                            filled: store.favorites.contains(item.id)
                        ) {
                            store.toggleFavorite(item.id)
                            Haptics.success()
                        }
                    }
                    .padding(.bottom, 22)
                }
            }
            .padding(22)
        }
        .canvasBackground()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Desk")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                DoubleRule()
                SlabButton(title: "Rate Us") { viewModel.rateApp() }
                SlabButton(title: "Privacy") { viewModel.openPrivacy() }
                SlabButton(title: "Terms") { viewModel.openTerms() }
                SlabButton(title: "Reset All Data", filled: false) {
                    viewModel.confirmReset = true
                }
            }
            .padding(22)
        }
        .canvasBackground()
        .confirmationDialog("Clear notes, captions, and pins?", isPresented: $viewModel.confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
