import UIKit

final class KeyboardDismissTap: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissTap()

    func install(on window: UIWindow) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func handle(_ gesture: UITapGestureRecognizer) {
        guard let root = gesture.view else { return }
        let hit = root.hitTest(gesture.location(in: root), with: nil)
        if isTextInput(hit) { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    private func isTextInput(_ view: UIView?) -> Bool {
        var current = view
        while let node = current {
            if node is UITextField || node is UITextView { return true }
            current = node.superview
        }
        return false
    }
}
