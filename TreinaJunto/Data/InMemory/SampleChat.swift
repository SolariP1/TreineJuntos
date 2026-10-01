import Foundation

extension SampleData {
    /// Monta o chat com um cenário plausível: já me dei bem com a Marina e
    /// conversamos; o Rafael me curtiu e está esperando eu curtir de volta.
    ///
    /// Sem isto a aba Chat nasceria vazia enquanto não houver servidor.
    static func seededChatRepository() -> InMemoryChatRepository {
        let marina = partners.first { $0.name == "Marina" }
        let rafael = partners.first { $0.name == "Rafael" }

        var conversas: [Conversation] = []
        var mensagens: [ChatMessage] = []

        if let marina, let conversa = try? Conversation.direct(
            between: meID,
            and: marina.id,
            now: Date().addingTimeInterval(-7200)
        ) {
            conversas.append(conversa)
            mensagens = [
                ChatMessage(
                    conversationID: conversa.id,
                    authorID: marina.id,
                    content: .text("Oi! Vi que você corre de manhã também 🏃‍♀️"),
                    createdAt: Date().addingTimeInterval(-7000)
                ),
                ChatMessage(
                    conversationID: conversa.id,
                    authorID: meID,
                    content: .text("Corro sim! Geralmente no Parque Vaca Brava"),
                    createdAt: Date().addingTimeInterval(-6800)
                )
            ]
        }

        return InMemoryChatRepository(
            likedMeBy: Set([marina?.id, rafael?.id].compactMap { $0 }),
            conversations: conversas,
            messages: mensagens
        )
    }
}
