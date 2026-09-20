import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var store: DataStore
    let destination: Destination
    @State private var showEdit = false
    @State private var showContact = false
    @State private var editingContact: ContactInfo?
    @State private var showNote = false
    @State private var editingNote: CulturalNote?
    @State private var packingTitle = ""
    @State private var packingCategory = PackingCategory.essentials.rawValue
    @State private var packingCarrier = ""
    @State private var packingError = ""
    @State private var confirmDelete = false
    @State private var showTemplates = false
    @State private var showSaveTemplate = false
    @State private var templateName = ""
    @State private var limitText = ""
    @State private var expenseTitle = ""
    @State private var expenseAmount = ""
    @State private var spendError = ""
    @State private var noteHint = ""

    private var live: Destination {
        store.destinations.first(where: { $0.id == destination.id }) ?? destination
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoBanner(name: "tile_trail")
                TicketCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(live.name)
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .foregroundColor(.white)
                        Text(live.region)
                            .foregroundColor(.white.opacity(0.75))
                        Text(live.visitDate.formatted(date: .long, time: .omitted))
                            .foregroundColor(Color("AppAccent"))
                        Text(live.isArchived ? "Archive" : live.status.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                sectionHeader("Local contacts", actionTitle: "Add") { showContact = true }
                let people = store.contacts(for: live.id)
                if people.isEmpty {
                    Text("No contacts yet. Add a local friend so packing hints can appear in the kit.")
                        .foregroundColor(.white.opacity(0.75))
                } else {
                    ForEach(people) { person in
                        TicketCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.name).foregroundColor(.white).font(.headline)
                                if !person.phone.isEmpty { Text(person.phone).foregroundColor(.white.opacity(0.7)) }
                                if !person.email.isEmpty { Text(person.email).foregroundColor(.white.opacity(0.7)) }
                                if !person.packingHint.isEmpty {
                                    Text("Kit hint: \(person.packingHint)")
                                        .foregroundColor(Color("AppAccent"))
                                }
                            }
                        }
                        .contextMenu {
                            Button("Edit") { editingContact = person; showContact = true }
                            Button("Delete", role: .destructive) { store.deleteContact(person) }
                        }
                    }
                }

                kitSection(people: people)
                spendSection
                notesSection
            }
            .padding(18)
        }
        .canvasBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit destination") { showEdit = true }
                    Button(live.isArchived ? "Restore from archive" : "Move to archive") {
                        var next = live
                        next.isArchived.toggle()
                        store.upsertDestination(next)
                    }
                    Button("Save kit as template") {
                        templateName = "\(live.name) kit"
                        showSaveTemplate = true
                    }
                    Button("Delete destination", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("AppAccent"))
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            DestinationEditorView(existing: live)
        }
        .sheet(isPresented: $showContact, onDismiss: { editingContact = nil }) {
            ContactEditorView(destinationId: live.id, existing: editingContact)
        }
        .sheet(isPresented: $showNote, onDismiss: { editingNote = nil }) {
            NoteEditorView(destinationId: live.id, existing: editingNote)
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerView(destinationId: live.id)
        }
        .alert("Save kit as template", isPresented: $showSaveTemplate) {
            TextField("Template name", text: $templateName)
            Button("Save") {
                let name = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { packingError = "Name the template first."; return }
                if store.saveTemplate(name: name, from: live.id) {
                    packingError = ""
                    Haptics.success()
                } else {
                    packingError = "Add kit items before saving a template."
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Remove this destination and its kit, contacts, and notes?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteDestination(live) }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            limitText = live.spendLimit == 0 ? "" : AmountText.format(live.spendLimit)
        }
        .onDisappear { commitLimit() }
    }

    @ViewBuilder
    private func kitSection(people: [ContactInfo]) -> some View {
        sectionHeader("Travel kit", actionTitle: "Templates") { showTemplates = true }
        let items = store.packing(for: live.id)
        let season = SeasonalKit.suggestions(for: live.visitDate).filter { hint in
            !items.contains { $0.title.compare(hint.title, options: .caseInsensitive) == .orderedSame }
        }
        if !season.isEmpty {
            TicketCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Season hints")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Suggestions for this visit month. Add only what you need.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    ForEach(season, id: \.title) { hint in
                        Text("· \(hint.title)")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    RaisedButton(title: "Add season hints", systemImage: "leaf") {
                        let added = store.addSeasonHints(to: live)
                        packingError = added == 0 ? "Those items are already in the kit." : ""
                        if added > 0 { Haptics.success() }
                    }
                }
            }
        }
        if items.isEmpty {
            EmptyStateView(symbol: "suitcase.fill", title: "Prepare your travel kit", detail: "Add items below, apply a template, or save a contact with a packing hint.")
        } else if items.contains(where: { !$0.carriedBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            let groups = Dictionary(grouping: items) { item -> String in
                let name = item.carriedBy.trimmingCharacters(in: .whitespacesAndNewlines)
                return name.isEmpty ? "Unassigned" : name
            }
            ForEach(groups.keys.sorted(), id: \.self) { carrier in
                Text(carrier)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("AppAccent"))
                ForEach(PackingCategory.allCases, id: \.rawValue) { category in
                    let group = (groups[carrier] ?? []).filter { $0.category == category.rawValue }
                    if !group.isEmpty {
                        Text(category.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.55))
                        ForEach(group) { item in
                            packingRow(item, people: people)
                        }
                    }
                }
            }
        } else {
            ForEach(PackingCategory.allCases, id: \.rawValue) { category in
                let group = items.filter { $0.category == category.rawValue }
                if !group.isEmpty {
                    Text(category.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("AppAccent"))
                    ForEach(group) { item in
                        packingRow(item, people: people)
                    }
                }
            }
        }
        VStack(alignment: .leading, spacing: 8) {
            TextField("New kit item", text: $packingTitle)
                .padding(12)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
            TextField("Carried by (optional)", text: $packingCarrier)
                .padding(12)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
            if !people.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "You", selected: packingCarrier == "You") { packingCarrier = "You" }
                        ForEach(people) { person in
                            FilterChip(title: person.name, selected: packingCarrier == person.name) {
                                packingCarrier = person.name
                            }
                        }
                    }
                }
            }
            Picker("Category", selection: $packingCategory) {
                ForEach(PackingCategory.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            if !packingError.isEmpty { Text(packingError).foregroundColor(.red).font(.caption) }
            RaisedButton(title: "Add to kit", systemImage: "plus") { addPacking() }
        }
    }

    private var spendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Spend", actionTitle: nil, action: nil)
            TicketCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Limit")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Optional cap", text: $limitText)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(Color("AppBackground").opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundColor(.white)
                        .onSubmit { commitLimit() }
                    let spent = store.spent(for: live.id)
                    Text("Logged \(AmountText.format(spent))" + (live.spendLimit > 0 ? " of \(AmountText.format(live.spendLimit))" : ""))
                        .foregroundColor(Color("AppAccent"))
                    if live.spendLimit > 0 {
                        ProgressView(value: min(spent, live.spendLimit), total: max(live.spendLimit, 1))
                            .tint(spent > live.spendLimit ? .red : Color("AppPrimary"))
                        if spent > live.spendLimit {
                            Text("Over by \(AmountText.format(spent - live.spendLimit))")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            let logs = store.expenses(for: live.id)
            ForEach(logs) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title).foregroundColor(.white)
                        Text(AmountText.format(entry.amount)).font(.caption).foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                    Button(role: .destructive) { store.deleteExpense(entry) } label: {
                        Image(systemName: "trash").foregroundColor(.white.opacity(0.55))
                    }
                }
                .padding(12)
                .background(Color("AppSurface").opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            TextField("What was this for", text: $expenseTitle)
                .padding(12)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
            TextField("Amount", text: $expenseAmount)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
            if !spendError.isEmpty { Text(spendError).foregroundColor(.red).font(.caption) }
            RaisedButton(title: "Log spend", systemImage: "plus") { addExpense() }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Cultural notes", actionTitle: "Add") { showNote = true }
            RaisedButton(title: "Add etiquette cards", systemImage: "hands.sparkles") {
                let added = store.addEtiquette(to: live)
                noteHint = added == 0 ? "Those cards are already in your notes." : ""
                if added > 0 { Haptics.success() }
            }
            if !noteHint.isEmpty {
                Text(noteHint).foregroundColor(.white.opacity(0.7)).font(.caption)
            }
            let notes = store.notes(for: live.id)
            if notes.isEmpty {
                Text("Start by adding your first destination insights.")
                    .foregroundColor(.white.opacity(0.75))
            } else {
                ForEach(notes) { note in
                    TicketCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.author).font(.caption.weight(.semibold)).foregroundColor(Color("AppAccent"))
                            Text(note.text).foregroundColor(.white)
                        }
                    }
                    .onTapGesture { editingNote = note; showNote = true }
                    .contextMenu {
                        Button("Delete", role: .destructive) { store.deleteNote(note) }
                    }
                }
            }
        }
    }

    private func packingRow(_ item: PackingItem, people: [ContactInfo]) -> some View {
        HStack {
            Button {
                var next = item
                next.isPacked.toggle()
                store.upsertPacking(next)
                if next.isPacked { Haptics.success() }
            } label: {
                Image(systemName: item.isPacked ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isPacked ? Color("AppAccent") : .white)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).foregroundColor(.white)
                if !item.suggestedBy.isEmpty {
                    Text("From \(item.suggestedBy)").font(.caption).foregroundColor(.white.opacity(0.6))
                }
                if !item.carriedBy.isEmpty {
                    Text("Carried by \(item.carriedBy)").font(.caption).foregroundColor(Color("AppAccent").opacity(0.9))
                }
            }
            Spacer()
            Menu {
                Button("Unassigned") { assign(item, to: "") }
                Button("You") { assign(item, to: "You") }
                ForEach(people) { person in
                    Button(person.name) { assign(item, to: person.name) }
                }
            } label: {
                Image(systemName: "person")
                    .foregroundColor(.white.opacity(0.7))
            }
            Button(role: .destructive) { store.deletePacking(item) } label: {
                Image(systemName: "trash")
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .padding(12)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionHeader(_ title: String, actionTitle: String?, action: (() -> Void)?) -> some View {
        HStack {
            Text(title).font(.system(.title3, design: .serif).weight(.semibold)).foregroundColor(.white)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .foregroundColor(Color("AppAccent"))
            }
        }
    }

    private func assign(_ item: PackingItem, to name: String) {
        var next = item
        next.carriedBy = name
        store.upsertPacking(next)
    }

    private func addPacking() {
        let title = packingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            packingError = "Enter an item name."
            return
        }
        let duplicate = store.packing(for: live.id).contains { $0.title.compare(title, options: .caseInsensitive) == .orderedSame }
        if duplicate {
            packingError = "That item is already in this kit."
            return
        }
        packingError = ""
        store.upsertPacking(
            PackingItem(
                destinationId: live.id,
                title: title,
                category: packingCategory,
                isPacked: false,
                suggestedBy: "You",
                carriedBy: packingCarrier.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        packingTitle = ""
        Haptics.success()
    }

    private func commitLimit() {
        guard store.destinations.contains(where: { $0.id == live.id }) else { return }
        var next = live
        next.spendLimit = AmountText.parse(limitText) ?? 0
        if next.spendLimit != live.spendLimit {
            store.upsertDestination(next)
        }
    }

    private func addExpense() {
        commitLimit()
        let title = expenseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            spendError = "Name the spend item."
            return
        }
        guard let amount = AmountText.parse(expenseAmount), amount > 0 else {
            spendError = "Enter an amount."
            return
        }
        spendError = ""
        store.upsertExpense(TripExpense(destinationId: live.id, title: title, amount: amount))
        expenseTitle = ""
        expenseAmount = ""
        Haptics.success()
    }
}

struct TemplatePickerView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Apply a saved kit or a built-in Winter, Beach, or City break list. Matching titles are skipped.")
                        .foregroundColor(.white.opacity(0.75))
                    ForEach(store.allTemplates) { template in
                        Button {
                            _ = store.applyTemplate(template, to: destinationId)
                            Haptics.success()
                            dismiss()
                        } label: {
                            TicketCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(template.name).font(.headline).foregroundColor(.white)
                                    Text("\(template.items.count) items")
                                        .foregroundColor(Color("AppAccent"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .canvasBackground()
            .navigationTitle("Kit templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ContactEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: ContactInfo?
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var hint = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Packing hint from this person", text: $hint)
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existing == nil ? "Add contact" : "Edit contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    phone = existing.phone
                    email = existing.email
                    hint = existing.packingHint
                }
            }
        }
        .canvasBackground()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Name is required."
            return
        }
        store.upsertContact(
            ContactInfo(
                id: existing?.id ?? UUID(),
                destinationId: destinationId,
                name: trimmed,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                packingHint: hint.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        Haptics.success()
        dismiss()
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: CulturalNote?
    @State private var author = ""
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Author", text: $author)
                TextField("Local tip", text: $text, axis: .vertical)
                    .lineLimit(4...10)
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existing == nil ? "Add note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    author = existing.author
                    text = existing.text
                }
            }
        }
        .canvasBackground()
    }

    private func save() {
        let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if a.isEmpty { error = "Add who shared this tip."; return }
        if t.isEmpty { error = "Write the advice before saving."; return }
        store.upsertNote(CulturalNote(id: existing?.id ?? UUID(), destinationId: destinationId, author: a, text: t))
        Haptics.success()
        dismiss()
    }
}
