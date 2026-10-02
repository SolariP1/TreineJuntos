import Foundation

/// O link que põe alguém num grupo sem curtida mútua.
///
/// É o único caminho em que um desconhecido entra numa conversa, então ele
/// expira e pode ser revogado (docs/PRODUTO.md §9.2).
struct GroupInviteLink: Hashable, Sendable {
    /// Validade padrão. Ainda em aberto no §9.7; uma semana é a sugestão.
    static let defaultLifetime: TimeInterval = 7 * 24 * 3600

    let token: String
    let conversationID: UUID
    let expiresAt: Date
    private(set) var revokedAt: Date?

    init(
        token: String = GroupInviteLink.makeToken(),
        conversationID: UUID,
        createdAt: Date = Date(),
        lifetime: TimeInterval = GroupInviteLink.defaultLifetime
    ) {
        self.token = token
        self.conversationID = conversationID
        expiresAt = createdAt.addingTimeInterval(lifetime)
        revokedAt = nil
    }

    var url: URL? {
        URL(string: "treinajunto://grupo/\(token)")
    }

    /// Diz por que o link não serve, ou nada se ele serve.
    func validate(now: Date = Date()) throws {
        if revokedAt != nil {
            throw ConversationError.linkRevoked
        }
        if now >= expiresAt {
            throw ConversationError.linkExpired
        }
    }

    mutating func revoke(now: Date = Date()) {
        guard revokedAt == nil else { return }
        revokedAt = now
    }

    /// Aleatório o bastante para não ser adivinhado. Com servidor, o banco
    /// guarda só o hash dele, pelo mesmo motivo do CPF.
    static func makeToken() -> String {
        var gerador = SystemRandomNumberGenerator()
        let alfabeto = Array("abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0 ..< 22).map { _ in alfabeto[Int(gerador.next() % UInt64(alfabeto.count))] })
    }
}
