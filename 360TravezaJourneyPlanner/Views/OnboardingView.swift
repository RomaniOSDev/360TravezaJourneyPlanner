import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("person.crop.circle.badge.plus", "Connect your travel", "Link each place with people you already know on the ground."),
        ("suitcase.fill", "Plan with insight", "Turn local advice into a packing list that actually matches the trip."),
        ("globe.europe.africa.fill", "Start exploring", "Add the first destination, then keep contacts, kit, and notes in one place.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 18) {
                        Image(index == 0 ? "tile_market" : (index == 1 ? "banner_pass" : "tile_trail"))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
                            .padding(.horizontal, 8)
                        Image(systemName: pages[index].0)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color("AppAccent"))
                        Text(pages[index].1)
                            .font(.system(.title, design: .serif).weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text(pages[index].2)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(.top, 24)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                        .foregroundColor(.white)
                }
                Spacer()
                Button(page == pages.count - 1 ? "Get started" : "Skip") {
                    store.completeOnboarding()
                }
                .foregroundColor(Color("AppAccent"))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .canvasBackground("bg_journey")
    }
}
