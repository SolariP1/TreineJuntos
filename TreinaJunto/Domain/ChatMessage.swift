import Foundation

/// Uma mensagem numa conversa.
///
/// Texto e convite de treino são o mesmo registro com conteúdo diferente,
/// como a tabela `messages` do docs/PRODUTO.md §9.5.
struct ChatMessage: Identifiable, Hashable, Sendable {
    enum Content: Hashable, Sendable {
        case text(String)
        /// O convite para um treino, que a tela desenha como card com
        /// Aceitar e Recusar.
        case workoutInvite(workoutID: UUID)
    }

    let id: UUID
    let conversationID: UUID
    let authorID: UUID
    let content: Content
    let createdAt: Date

    init(
        id: UUID = UUID(),
        conversationID: UUID,
        authorID: UUID,
        content: Content,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationID = conversationID
        self.authorID = authorID
        self.content = content
        self.createdAt = createdAt
    }
}
