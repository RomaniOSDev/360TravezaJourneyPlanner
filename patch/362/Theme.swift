import Foundation
import SwiftUI
import UIKit

enum AppLinks {
    static let privacy = "https://adminka.site/privacy/474"
    static let terms = "https://example.com/terms"
}

extension View {
    func canvasBackground(_ image: String = "bg_spices") -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.14)
                    }
                    .overlay { PaperRules() }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

struct PaperRules: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y: CGFloat = 18
            while y < size.height {
                path.move(to: CGPoint(x: 28, y: y))
                path.addLine(to: CGPoint(x: size.width - 12, y: y))
                y += 28
            }
            context.stroke(path, with: .color(Color("AppPrimary").opacity(0.08)), lineWidth: 1)
            var margin = Path()
            margin.move(to: CGPoint(x: 22, y: 0))
            margin.addLine(to: CGPoint(x: 22, y: size.height))
            context.stroke(margin, with: .color(Color.red.opacity(0.18)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
