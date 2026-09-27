import Foundation

/// Quem está usando o app.
///
/// Hoje não há autenticação de verdade: `signIn` só registra que alguém
/// entrou. O protocolo existe para que, quando houver servidor, trocar por
/// Sign in with Apple seja implementar isto — e não mexer em tela.
protocol SessionStore: Sendable {
    /// A sessão gravada, se alguém já entrou neste aparelho.
    func currentSession() async -> Session?
    func signIn(method: SignInMethod) async throws -> Session
    func signOut() async
}

/// Quem entrou, e por onde.
struct Session: Codable, Hashable, Sendable {
    let userID: UUID
    let method: SignInMethod
    let startedAt: Date

    init(userID: UUID = UUID(), method: SignInMethod, startedAt: Date = Date()) {
        self.userID = userID
        self.method = method
        self.startedAt = startedAt
    }
}

enum SignInMethod: String, Codable, Sendable {
    case apple
    case google
    case email
}
