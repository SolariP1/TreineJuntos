import Foundation

/// Guarda a sessão no `UserDefaults`.
///
/// Só o identificador e por onde a pessoa entrou — **nenhuma credencial**.
/// Quando houver autenticação de verdade, o token vai para o Keychain, não
/// para cá: `UserDefaults` é um plist legível por quem tiver o backup do
/// aparelho.
actor UserDefaultsSessionStore: SessionStore {
    private let defaults: UserDefaults
    private let key = "br.com.treinajunto.session"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentSession() async -> Session? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Session.self, from: data)
    }

    func signIn(method: SignInMethod) async throws -> Session {
        let session = Session(method: method)
        try defaults.set(JSONEncoder().encode(session), forKey: key)
        return session
    }

    func signOut() async {
        defaults.removeObject(forKey: key)
    }
}
