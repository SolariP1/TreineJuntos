import Foundation

/// Quem está usando o app, para o app inteiro.
///
/// Substitui o `@State private var isLoggedIn` que vivia dentro do
/// `RootView`: ali a resposta para "quem sou eu" morria com a View e sumia
/// ao fechar o app.
@Observable
@MainActor
final class AppSession {
    enum State {
        /// Ainda lendo o que está gravado no aparelho.
        case restoring
        case signedOut
        case signedIn(Session)
    }

    private(set) var state: State = .restoring

    private let store: SessionStore

    init(store: SessionStore) {
        self.store = store
    }

    var isSignedIn: Bool {
        if case .signedIn = state {
            return true
        }
        return false
    }

    /// Lê a sessão gravada. Chamado uma vez, na abertura.
    func restore() async {
        if let session = await store.currentSession() {
            state = .signedIn(session)
        } else {
            state = .signedOut
        }
    }

    func signIn(method: SignInMethod) async {
        do {
            state = try await .signedIn(store.signIn(method: method))
        } catch {
            state = .signedOut
        }
    }

    func signOut() async {
        await store.signOut()
        state = .signedOut
    }
}
