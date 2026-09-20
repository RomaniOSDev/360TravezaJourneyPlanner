import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var tab: KitchenTab = .blends
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                HStack(spacing: 0) {
                    tabBody
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    chapterTabs
                }
                .canvasBackground()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if scenePhase == .active {
                store.tickTimers()
            }
        }
    }

    @ViewBuilder
    private var tabBody: some View {
        switch tab {
        case .blends: BlendLibraryView()
        case .recipes: RecipeListView()
        case .market: MarketView()
        case .timers: TimerBoardView()
        case .settings: SettingsView()
        }
    }

    private var chapterTabs: some View {
        VStack(spacing: 0) {
            ForEach(KitchenTab.allCases, id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    Text(item.title)
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .rotationEffect(.degrees(90))
                        .fixedSize()
                        .frame(width: 36, height: 78)
                        .foregroundColor(tab == item ? .white : Color("AppPrimary"))
                        .background(tab == item ? Color("AppPrimary") : Color.white.opacity(0.7))
                        .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 24)
        .background(Color("AppAccent").opacity(0.18))
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var page = 0
    private let pages = [
        ("Discover spices", "A shelf of seeds, barks, and herbs to cook from."),
        ("Create blends", "Two spices make a jar. The market list follows."),
        ("Start crafting", "Plates and timers take the name of the blend.")
    ]

    var body: some View {
        VStack(spacing: 18) {
            Polaroid(image: page == 0 ? "banner_herbs" : (page == 1 ? "tile_mortar" : "tile_pan"), tilt: page == 1 ? 4 : -3)
                .padding(.horizontal, 36)
                .padding(.top, 28)
            Text(pages[page].0)
                .font(.system(size: 32, design: .serif))
                .foregroundColor(Color("AppPrimary"))
                .multilineTextAlignment(.center)
            Text(pages[page].1)
                .font(.system(.body, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                Button(page == 2 ? "Open the kitchen" : "Skip") { store.completeOnboarding() }
                    .font(.system(.body, design: .serif).weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
            }
            .padding(24)
        }
        .canvasBackground()
    }
}
