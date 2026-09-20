import SwiftUI

struct LogPane: View {
    @EnvironmentObject private var store: DataStore
    @State private var showEditor = false
    @State private var editing: RoadLog?
    @State private var filter: SurfaceKind?

    var body: some View {
        let items = filtered
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                filterTab("ALL", active: filter == nil) { filter = nil }
                ForEach(SurfaceKind.allCases) { kind in
                    filterTab(kind.title.uppercased(), active: filter == kind) { filter = kind }
                }
            }
            .overlay(alignment: .bottom) { Rectangle().fill(Color("AppAccent").opacity(0.35)).frame(height: 1) }

            if store.routes.isEmpty {
                Spacer()
                Text("NO ROAD CONDITION HISTORY YET")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("AppAccent"))
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if items.isEmpty {
                Spacer()
                Text("FILTER EMPTY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            } else {
                List {
                    ForEach(items) { item in
                        Button {
                            editing = item
                            showEditor = true
                        } label: {
                            HStack(alignment: .top) {
                                Text(item.surface.title.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("AppBackground"))
                                    .frame(width: 28, height: 28)
                                    .background(Color("AppAccent"))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(routeName(item.routeId).uppercased())
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.55))
                                    if !item.note.isEmpty {
                                        Text(item.note)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                Spacer()
                                Text("\(item.temperature)°")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("AppAccent"))
                            }
                        }
                        .listRowBackground(Color.black.opacity(0.28))
                        .listRowSeparatorTint(Color("AppAccent").opacity(0.2))
                    }
                    .onDelete { indexSet in
                        indexSet.map { items[$0] }.forEach(store.deleteLog)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            Button {
                editing = nil
                showEditor = true
            } label: {
                Text("+ LOG RIDE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(store.routes.isEmpty ? Color.white.opacity(0.15) : Color("AppAccent"))
                    .foregroundColor(store.routes.isEmpty ? .white.opacity(0.4) : Color("AppBackground"))
            }
            .buttonStyle(.plain)
            .disabled(store.routes.isEmpty)
            .padding(12)
        }
        .sheet(isPresented: $showEditor, onDismiss: { editing = nil }) {
            LogEditorView(existing: editing)
        }
    }

    private var filtered: [RoadLog] {
        let base = store.logs
        if let filter { return base.filter { $0.surface == filter } }
        return base
    }

    private func routeName(_ id: UUID) -> String {
        store.routes.first(where: { $0.id == id })?.name ?? "Corridor"
    }

    private func filterTab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? Color("AppAccent") : Color.clear)
                .foregroundColor(active ? Color("AppBackground") : .white.opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}

struct LogEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: RoadLog?
    @State private var routeId: UUID = UUID()
    @State private var date = Date()
    @State private var surface: SurfaceKind = .dry
    @State private var temperature = 12
    @State private var wind = 8
    @State private var note = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Corridor", selection: $routeId) {
                    ForEach(store.routes) { Text($0.name).tag($0.id) }
                }
                DatePicker("When", selection: $date, in: ...Date())
                Picker("Surface", selection: $surface) {
                    ForEach(SurfaceKind.allCases) { Text($0.title).tag($0) }
                }
                Stepper("Temperature \(temperature)°", value: $temperature, in: -15...40)
                Stepper("Wind \(wind)", value: $wind, in: 0...40)
                TextField("Annotation", text: $note)
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existing == nil ? "New log" : "Edit log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let existing {
                    routeId = existing.routeId
                    date = existing.date
                    surface = existing.surface
                    temperature = existing.temperature
                    wind = existing.wind
                    note = existing.note
                } else if let selected = store.selectedRouteId {
                    routeId = selected
                } else if let first = store.routes.first {
                    routeId = first.id
                }
            }
        }
        .canvasBackground()
    }

    private func save() {
        if store.routes.isEmpty {
            error = "Add a corridor first."
            return
        }
        if date > Date() {
            error = "Future dates are not allowed."
            return
        }
        store.upsertLog(
            RoadLog(
                id: existing?.id ?? UUID(),
                routeId: routeId,
                date: date,
                surface: surface,
                temperature: temperature,
                wind: wind,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        Haptics.success()
        dismiss()
    }
}

struct InsightPane: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ViewfinderCrop(image: "tile_ice", height: 80)
                if store.routes.isEmpty {
                    Text("NO RECORDED CONDITIONS YET — START YOUR JOURNEY SAFELY!")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(12)
                        .overlay(Bezel())
                } else {
                    ForEach(store.routes) { route in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(route.name.uppercased())
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(store.predictedSurface(for: route.id).title.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("AppAccent"))
                            }
                            RiskMeter(progress: store.riskScore(for: route.id))
                            Text(store.insightLine(for: route.id))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.78))
                            Text("RIDES \(store.logs(for: route.id).count)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.38))
                        .overlay(Bezel())
                    }
                }
            }
            .padding(12)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("CFG")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(Color("AppAccent"))
                TerminalRow(command: "RATE_US") { viewModel.rateApp() }
                TerminalRow(command: "PRIVACY") { viewModel.openPrivacy() }
                TerminalRow(command: "TERMS") { viewModel.openTerms() }
                Button {
                    viewModel.confirmReset = true
                } label: {
                    HStack {
                        Text(">")
                        Text("RESET_ALL_DATA")
                        Spacer()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .confirmationDialog("Clear corridors, logs, and insight history?", isPresented: $viewModel.confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
