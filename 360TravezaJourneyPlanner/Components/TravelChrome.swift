import SwiftUI

struct TicketCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("AppSurface").opacity(0.92))
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color("AppAccent").opacity(0.7), Color("AppPrimary").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct RaisedButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color("AppPrimary").opacity(0.4), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(Color("AppAccent"))
                .shadow(color: Color("AppPrimary").opacity(0.5), radius: 8, y: 4)
            Text(title)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.callout)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("AppSurface").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 8)
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(selected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Color("AppAccent") : Color("AppSurface"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PhotoBanner: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.05), Color.black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
    }
}
