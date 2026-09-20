import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                DestinationListView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}
