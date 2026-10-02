import Foundation

/// Uma conversa com o que a lista do Chat precisa para desenhar: quem está
/// do outro lado e a última mensagem.
struct ConversationSummary: Identifiable, Hashable, Sendable {
    let conversation: Conversation
    /// Todo mundo menos eu, na ordem em que entrou.
    let others: [WorkoutPartner]
    let lastMessage: ChatMessage?

    var id: UUID {
        conversation.id
    }

    var isGroup: Bool {
        conversation.kind == .group
    }

    /// Privada mostra o nome da pessoa — na prática parece uma conversa por
    /// pessoa, que é o que todo mundo espera ver.
    var title: String {
        if isGroup {
            return conversation.name ?? "Grupo"
        }
        return others.first?.name ?? "Conversa"
    }

    /// Quem escreveu, para a tela pôr o nome em cima do balão no grupo.
    func author(of message: ChatMessage) -> WorkoutPartner? {
        others.first { $0.id == message.authorID }
    }
}
