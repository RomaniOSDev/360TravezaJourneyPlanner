import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                NavigationStack {
                    StudioIndexView()
                }
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var page = 0
    private let pages = [
        ("Capture ideas", "Keep room layouts as notes you can reopen on site."),
        ("Add details", "Write captions for furnishings, colors, and placement."),
        ("Start a project", "Open a space, then pin inspirations into the same file.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("VOL. I  ·  STUDIO EDITION")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(Color("AppAccent"))
                .padding(.horizontal, 20)
                .padding(.top, 18)
            Text(pages[page].0)
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundColor(Color("AppPrimary"))
                .padding(.horizontal, 20)
                .padding(.top, 8)
            DoubleRule()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            Cutline(
                image: page == 0 ? "bg_living" : (page == 1 ? "banner_chair" : "tile_plants"),
                height: 220,
                caption: page == 0 ? "Figure 1 — living bay" : (page == 1 ? "Figure 2 — lounge chair" : "Figure 3 — atrium")
            )
            .padding(.horizontal, 20)
            Text(pages[page].1)
                .font(.system(.body, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.75))
                .padding(20)
            Spacer()
            HStack {
                if page > 0 {
                    Button("BACK") { page -= 1 }
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                Button(page == 2 ? "ENTER STUDIO" : "SKIP") { store.completeOnboarding() }
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Color("AppAccent"))
            }
            .padding(20)
        }
        .canvasBackground()
    }
}

struct StudioIndexView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year()).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.8)
                    .foregroundColor(Color("AppAccent"))
                Text("Studio record")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.top, 4)
                Text("Rooms, captions, and borrowed ideas — set in type.")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.55))
                    .padding(.bottom, 10)
                DoubleRule()
                Cutline(image: "banner_chair", height: 168, caption: "Above — a chair held in daylight")
                    .padding(.vertical, 14)
                NavigationLink {
                    NotesGalleryView()
                } label: {
                    LeaderRow(number: "01", title: "Room notes", subtitle: "\(store.notes.count) spaces on file")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    CaptionStudioView()
                } label: {
                    LeaderRow(number: "02", title: "Captions", subtitle: "\(store.captions.count) annotations")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    InspirationView()
                } label: {
                    LeaderRow(number: "03", title: "Discover", subtitle: "\(store.favorites.count) pinned cuts")
                }
                .buttonStyle(.plain)
                Hairline()
                NavigationLink {
                    SettingsView()
                } label: {
                    LeaderRow(number: "04", title: "Desk", subtitle: "Rate, privacy, terms")
                }
                .buttonStyle(.plain)
                Hairline()
            }
            .padding(22)
        }
        .canvasBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
