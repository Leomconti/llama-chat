import SwiftUI

// MARK: - Animation Constants
enum AnimationConstants {
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
    static let scalePressed: CGFloat = 0.97

    enum Transitions {
        static let buttonTransition = AnyTransition.scale.combined(with: .opacity)
        static let messageTransition = AnyTransition.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
}

// MARK: - View Modifiers
struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? AnimationConstants.scalePressed : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                pressing: { pressing in
                    withAnimation {
                        isPressed = pressing
                    }
                }, perform: {})
    }
}

struct MessageAnimationModifier: ViewModifier {
    let message: ChatMessage
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func pressAnimation() -> some View {
        modifier(PressAnimationModifier())
    }
}
