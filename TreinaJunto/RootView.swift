import SwiftUI

struct RootView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            MainTabView(onLogout: {
                withAnimation(.rootTransition) { isLoggedIn = false }
            })
            .transition(.loginReveal)
        } else {
            OnboardingView(onContinue: {
                withAnimation(.rootTransition) { isLoggedIn = true }
            })
            .transition(.loginDismiss)
        }
    }
}

private extension Animation {
    /// Spring with a touch of overshoot — reads as a confident "you're in"
    /// moment rather than a flat cross-fade.
    static let rootTransition = Animation.spring(response: 0.55, dampingFraction: 0.82)
}

private extension AnyTransition {
    /// The signed-in app rises in from below with a soft fade+scale, while
    /// the screen underneath eases back — gives login a sense of depth
    /// instead of a plain crossfade.
    static let loginReveal = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity)
            .combined(with: .scale(scale: 0.97, anchor: .top)),
        removal: .opacity
    )

    static let loginDismiss = AnyTransition.asymmetric(
        insertion: .opacity,
        removal: .scale(scale: 1.04, anchor: .center).combined(with: .opacity)
    )
}

#Preview {
    RootView()
}
