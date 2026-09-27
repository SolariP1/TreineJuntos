import SwiftUI

struct RootView: View {
    @Environment(\.dependencies) private var dependencies

    @State private var session: AppSession?

    var body: some View {
        Group {
            switch session?.state {
            case .signedIn:
                MainTabView(onLogout: {
                    Task {
                        await session?.signOut()
                    }
                })
                .transition(.loginReveal)

            case .signedOut:
                OnboardingView { method in
                    Task { await session?.signIn(method: method) }
                }
                .transition(.loginDismiss)

            case .none, .restoring:
                // Enquanto lê o que está gravado. Sem isto, quem já entrou
                // veria o onboarding piscar antes de cair no Feed.
                ZStack {
                    Playful.canvas.ignoresSafeArea()
                    ProgressView().tint(Palette.accent.base)
                }
            }
        }
        .animation(.rootTransition, value: session?.isSignedIn)
        .task {
            if session == nil {
                session = AppSession(store: dependencies.session)
            }
            await session?.restore()
        }
    }
}

private extension Animation {
    /// Mola com um toque de passar do ponto — lê como um "você entrou"
    /// confiante, em vez de um cross-fade chapado.
    static let rootTransition = Animation.spring(response: 0.55, dampingFraction: 0.82)
}

private extension AnyTransition {
    /// O app logado sobe de baixo com um fade e escala suaves, enquanto a
    /// tela de trás recua — dá profundidade ao login em vez de um
    /// cross-fade simples.
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
