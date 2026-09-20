import SwiftUI

extension View {
    func canvasBackground(_ image: String = "bg_journey") -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.42)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
            .scrollDismissesKeyboard(.immediately)
    }
}
