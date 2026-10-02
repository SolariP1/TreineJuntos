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
    private let partners: [UUID: WorkoutPartner]

    init(
        meID: UUID = SampleData.meID,
        likedMeBy: Set<UUID> = [],
        conversations: [Conversation] = [],
        messages: [ChatMessage] = [],
        links: [GroupInviteLink] = [],
        partners: [WorkoutPartner] = SampleData.partners,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.meID = meID
        self.likedMeBy = likedMeBy
        self.now = now
        conversationsByID = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0) })
        messagesByConversation = Dictionary(grouping: messages, by: \.conversationID)
        self.links = Dictionary(uniqueKeysWithValues: links.map { ($0.conversationID, $0) })
        self.partners = Dictionary(uniqueKeysWithValues: partners.map { ($0.id, $0) })
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

    func summaries() async throws -> [ConversationSummary] {
        try await conversations().map { conversa in
            ConversationSummary(
                conversation: conversa,
                // Quem não tem perfil conhecido some da lista em vez de
                // aparecer sem nome.
                others: conversa.memberIDs.filter { $0 != meID }.compactMap { partners[$0] },
                lastMessage: messagesByConversation[conversa.id]?.last
            )
        }
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

    func currentInviteLink(for conversationID: UUID) async throws -> GroupInviteLink? {
        _ = try myConversation(conversationID)
        guard let link = links[conversationID], (try? link.validate(now: now())) != nil else {
            return nil
        }
        return link
    }

    func revokeInviteLink(for conversationID: UUID) async throws {
        let grupo = try myConversation(conversationID)
        guard grupo.createdBy == meID else { throw ConversationError.notGroupCreator }
        links[conversationID]?.revoke(now: now())
    }

    func previewGroup(withToken token: String) async throws -> ConversationSummary {
        let grupo = try group(forToken: token)
        return ConversationSummary(
            conversation: grupo,
            others: grupo.memberIDs.filter { $0 != meID }.compactMap { partners[$0] },
            // Quem ainda não entrou não lê o que foi dito antes.
            lastMessage: nil
        )
    }

    @discardableResult
    func joinGroup(withToken token: String) async throws -> Conversation {
        var grupo = try group(forToken: token)
        try grupo.add(meID)
        conversationsByID[grupo.id] = grupo
        return grupo
    }

    // MARK: - Apoio

    private func group(forToken token: String) throws -> Conversation {
        guard let link = links.values.first(where: { $0.token == token }) else {
            throw ConversationError.linkNotFound
        }
        try link.validate(now: now())
        guard let grupo = conversationsByID[link.conversationID] else {
            throw ConversationError.conversationNotFound
        }
        return grupo
    }

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

#if DEBUG
    extension InMemoryChatRepository {
        /// Simula todo mundo que eu curti me curtindo de volta. Devolve
        /// quantas conversas novas abriram.
        func debugEveryoneLikesBack() throws -> Int {
            var novas = 0
            for id in myLikes where directConversationExists(with: id) == false {
                if try receiveLike(from: id) != nil {
                    novas += 1
                }
            }
            return novas
        }

        /// Um grupo criado por outra pessoa, com link valendo — o que chegaria
        /// por WhatsApp para alguém abrir.
        func debugForeignGroupLink(createdBy creatorID: UUID, named name: String) throws -> GroupInviteLink {
            let grupo = try Conversation.group(named: name, createdBy: creatorID, members: [], now: now())
            conversationsByID[grupo.id] = grupo
            let link = GroupInviteLink(conversationID: grupo.id, createdAt: now())
            links[grupo.id] = link
            return link
        }

        private func directConversationExists(with profileID: UUID) -> Bool {
            conversationsByID.values.contains {
                $0.kind == .direct && $0.contains(meID) && $0.contains(profileID)
            }
        }
    }
#endif
