import Foundation

/// Curtidas, conversas e grupos.
///
/// Mesma costura dos outros repositórios — hoje em memória, amanhã Supabase,
/// sem tela mudando.
protocol ChatRepository: Sendable {
    /// Curto alguém. Se a pessoa já tinha me curtido, nasce a conversa
    /// privada e ela volta aqui; senão volta `nil` e ninguém fica sabendo.
    @discardableResult
    func like(_ profileID: UUID) async throws -> Conversation?

    /// Minhas conversas, da mais recente para a mais antiga.
    func conversations() async throws -> [Conversation]

    /// As mesmas conversas, já com quem está do outro lado e a última
    /// mensagem — o que a lista do Chat desenha.
    func summaries() async throws -> [ConversationSummary]

    /// As mensagens de uma conversa, da mais antiga para a mais nova.
    func messages(in conversationID: UUID) async throws -> [ChatMessage]

    @discardableResult
    func send(_ content: ChatMessage.Content, to conversationID: UUID) async throws -> ChatMessage

    /// Crio um grupo chamando gente das minhas conversas privadas.
    func createGroup(named name: String, with memberIDs: [UUID]) async throws -> Conversation

    /// Gera um link novo para o grupo. O anterior deixa de valer.
    func createInviteLink(for conversationID: UUID) async throws -> GroupInviteLink

    /// O link que vale agora, se houver.
    func currentInviteLink(for conversationID: UUID) async throws -> GroupInviteLink?

    func revokeInviteLink(for conversationID: UUID) async throws

    /// O grupo de um link, para a pessoa ver quem está lá **antes** de
    /// decidir entrar.
    func previewGroup(withToken token: String) async throws -> ConversationSummary

    /// Entro num grupo pelo link.
    @discardableResult
    func joinGroup(withToken token: String) async throws -> Conversation
}
