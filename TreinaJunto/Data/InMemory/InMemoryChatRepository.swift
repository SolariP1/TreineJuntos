import Foundation

/// Curtidas, conversas e grupos guardados em memória, enquanto não existe
/// servidor.
///
/// As regras de cada conversa ficam no domínio; aqui fica o que depende de
/// olhar o todo — curtida mútua, quem está nas minhas conversas, link
/// valendo.
actor InMemoryChatRepository: ChatRepository {
    private let meID: UUID
    private let now: @Sendable () -> Date
    /// Quem já me curtiu. Com servidor, isto é a tabela `likes` vista do
    /// outro lado — o app nunca mostra essa lista.
    private var likedMeBy: Set<UUID>
    private var myLikes: Set<UUID> = []
    private var conversationsByID: [UUID: Conversation] = [:]
    private var messagesByConversation: [UUID: [ChatMessage]] = [:]
    /// Um link valendo por grupo, pela chave do grupo.
    private var links: [UUID: GroupInviteLink] = [:]

    init(
        meID: UUID = SampleData.meID,
        likedMeBy: Set<UUID> = [],
        conversations: [Conversation] = [],
        messages: [ChatMessage] = [],
        links: [GroupInviteLink] = [],
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.meID = meID
        self.likedMeBy = likedMeBy
        self.now = now
        conversationsByID = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0) })
        messagesByConversation = Dictionary(grouping: messages, by: \.conversationID)
        self.links = Dictionary(uniqueKeysWithValues: links.map { ($0.conversationID, $0) })
    }

    // MARK: - Curtida

    @discardableResult
    func like(_ profileID: UUID) async throws -> Conversation? {
        if let existente = directConversation(with: profileID) {
            return existente
        }
        myLikes.insert(profileID)
        guard likedMeBy.contains(profileID) else { return nil }

        let conversa = try Conversation.direct(between: meID, and: profileID, now: now())
        conversationsByID[conversa.id] = conversa
        return conversa
    }

    /// O outro lado me curtiu. Em memória é assim que a curtida dele chega;
    /// com servidor, chega por Realtime.
    @discardableResult
    func receiveLike(from profileID: UUID) throws -> Conversation? {
        likedMeBy.insert(profileID)
        guard myLikes.contains(profileID), directConversation(with: profileID) == nil else {
            return directConversation(with: profileID)
        }
        let conversa = try Conversation.direct(between: meID, and: profileID, now: now())
        conversationsByID[conversa.id] = conversa
        return conversa
    }

    // MARK: - Conversas

    func conversations() async throws -> [Conversation] {
        conversationsByID.values
            .filter { $0.contains(meID) }
            .sorted { lastActivity(of: $0) > lastActivity(of: $1) }
    }

    func messages(in conversationID: UUID) async throws -> [ChatMessage] {
        _ = try myConversation(conversationID)
        return messagesByConversation[conversationID, default: []]
    }

    @discardableResult
    func send(_ content: ChatMessage.Content, to conversationID: UUID) async throws -> ChatMessage {
        try deliver(content, from: meID, to: conversationID)
    }

    /// Alguém da conversa escreveu. Em memória é assim que a mensagem dele
    /// chega; com servidor, chega por Realtime.
    @discardableResult
    func deliver(
        _ content: ChatMessage.Content,
        from authorID: UUID,
        to conversationID: UUID
    ) throws -> ChatMessage {
        guard let conversa = conversationsByID[conversationID] else {
            throw ConversationError.conversationNotFound
        }
        guard conversa.contains(authorID) else { throw ConversationError.notAMember }

        var conteudo = content
        if case let .text(texto) = content {
            let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !limpo.isEmpty else { throw ConversationError.emptyMessage }
            conteudo = .text(limpo)
        }

        let mensagem = ChatMessage(
            conversationID: conversationID,
            authorID: authorID,
            content: conteudo,
            createdAt: now()
        )
        messagesByConversation[conversationID, default: []].append(mensagem)
        return mensagem
    }

    // MARK: - Grupos

    func createGroup(named name: String, with memberIDs: [UUID]) async throws -> Conversation {
        // Sem curtida mútua, ninguém entra por escolha minha — só pelo link,
        // que a pessoa abre se quiser.
        for id in memberIDs where id != meID && directConversation(with: id) == nil {
            throw ConversationError.notInMyConversations
        }
        let grupo = try Conversation.group(named: name, createdBy: meID, members: memberIDs, now: now())
        conversationsByID[grupo.id] = grupo
        return grupo
    }

    func createInviteLink(for conversationID: UUID) async throws -> GroupInviteLink {
        let grupo = try myConversation(conversationID)
        guard grupo.kind == .group else { throw ConversationError.directIsAlwaysTwo }
        guard grupo.createdBy == meID else { throw ConversationError.notGroupCreator }

        let link = GroupInviteLink(conversationID: conversationID, createdAt: now())
        links[conversationID] = link
        return link
    }

    func revokeInviteLink(for conversationID: UUID) async throws {
        let grupo = try myConversation(conversationID)
        guard grupo.createdBy == meID else { throw ConversationError.notGroupCreator }
        links[conversationID]?.revoke(now: now())
    }

    @discardableResult
    func joinGroup(withToken token: String) async throws -> Conversation {
        guard let link = links.values.first(where: { $0.token == token }) else {
            throw ConversationError.linkNotFound
        }
        try link.validate(now: now())
        guard var grupo = conversationsByID[link.conversationID] else {
            throw ConversationError.conversationNotFound
        }
        try grupo.add(meID)
        conversationsByID[grupo.id] = grupo
        return grupo
    }

    // MARK: - Apoio

    private func directConversation(with profileID: UUID) -> Conversation? {
        conversationsByID.values.first {
            $0.kind == .direct && $0.contains(meID) && $0.contains(profileID)
        }
    }

    private func myConversation(_ id: UUID) throws -> Conversation {
        guard let conversa = conversationsByID[id] else { throw ConversationError.conversationNotFound }
        guard conversa.contains(meID) else { throw ConversationError.notAMember }
        return conversa
    }

    private func lastActivity(of conversation: Conversation) -> Date {
        messagesByConversation[conversation.id]?.last?.createdAt ?? conversation.createdAt
    }
}
