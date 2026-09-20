import Combine
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var confirmReset = false
    func openPrivacy() {
        if let url = URL(string: AppLinks.privacy) { UIApplication.shared.open(url) }
    }
    func openTerms() {
        if let url = URL(string: AppLinks.terms) { UIApplication.shared.open(url) }
    }
    func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

enum KitchenTab: String, CaseIterable {
    case blends
    case recipes
    case market
    case timers
    case settings

    var title: String {
        switch self {
        case .blends: return "Jars"
        case .recipes: return "Plates"
        case .market: return "List"
        case .timers: return "Time"
        case .settings: return "Desk"
        }
    }
}

struct Polaroid: View {
    let image: String
    var tilt: Double = -3

    var body: some View {
        VStack(spacing: 8) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(height: 118)
                .clipped()
            Rectangle()
                .fill(Color("AppPrimary").opacity(0.28))
                .frame(width: 52, height: 5)
        }
        .padding(10)
        .background(Color.white)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 2, y: 6)
        .rotationEffect(.degrees(tilt))
    }
}

struct RecipeCard: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            Text(detail)
                .font(.system(.footnote, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .overlay(alignment: .leading) {
            Rectangle().fill(Color("AppPrimary")).frame(width: 5)
        }
                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 1, y: 2)
    }
}

struct StampButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .serif).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color("AppPrimary"))
                .foregroundColor(.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .padding(3)
                )
                .shadow(color: Color("AppPrimary").opacity(0.28), radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
    }
}
