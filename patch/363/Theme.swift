import Foundation
import SwiftUI
import UIKit

enum AppLinks {
    static let privacy = "https://adminka.site/privacy/475"
    static let terms = "https://example.com/terms"
}

extension View {
    func canvasBackground(_ image: String = "bg_living") -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.08)
                    }
                    .overlay { ColumnRules() }
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

struct ColumnRules: View {
    var body: some View {
        Canvas { context, size in
            let gutter = size.width / 3
            var path = Path()
            path.move(to: CGPoint(x: gutter, y: 40))
            path.addLine(to: CGPoint(x: gutter, y: size.height - 24))
            path.move(to: CGPoint(x: gutter * 2, y: 40))
            path.addLine(to: CGPoint(x: gutter * 2, y: size.height - 24))
            context.stroke(path, with: .color(Color.black.opacity(0.06)), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
    }
}
