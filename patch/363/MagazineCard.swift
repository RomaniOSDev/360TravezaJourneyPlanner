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

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Color("AppPrimary"))
            .frame(height: 1)
    }
}

struct DoubleRule: View {
    var body: some View {
        VStack(spacing: 3) {
            Rectangle().fill(Color("AppPrimary")).frame(height: 2)
            Rectangle().fill(Color("AppPrimary")).frame(height: 1)
        }
    }
}

struct Cutline: View {
    let image: String
    var height: CGFloat = 140
    var caption: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 1))
            if !caption.isEmpty {
                Text(caption.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundColor(Color("AppAccent"))
            }
        }
    }
}

struct SlabButton: View {
    let title: String
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .tracking(1.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(filled ? Color("AppPrimary") : Color.clear)
                .foregroundColor(filled ? Color("AppBackground") : Color("AppPrimary"))
                .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

struct LeaderRow: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(number)
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundColor(Color("AppAccent"))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text(subtitle)
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.55))
            }
            Spacer()
            Text("»")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(Color("AppAccent"))
        }
        .padding(.vertical, 10)
    }
}
