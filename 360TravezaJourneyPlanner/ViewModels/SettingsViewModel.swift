import Combine
import StoreKit
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var confirmReset = false

    func openPrivacy() {
        if let url = URL(string: AppLinks.privacy) {
            UIApplication.shared.open(url)
        }
    }

    func openTerms() {
        if let url = URL(string: AppLinks.terms) {
            UIApplication.shared.open(url)
        }
    }

    func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
