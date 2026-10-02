import Foundation
import Testing
@testable import TreinaJunto

@MainActor
@Suite("Chat · Lista")
struct ChatListViewModelTests {
    private let marina = SampleData.partners[0]
    private let beatriz = SampleData.partners[2]
    private let rafael = SampleData.partners[3]

    @Test("Carregar traz as conversas com o nome de quem está do outro lado")
    func loadShowsPartnerNames() async {
        let model = ChatListViewModel(repository: SampleData.seededChatRepository())

        await model.load()

        #expect(model.conversations.value?.map(\.title) == ["Marina"])
        #expect(model.conversations.value?.first?.lastMessage != nil)
    }

    @Test("Os contatos para um grupo são as pessoas das conversas privadas")
    func contactsComeFromDirectConversations() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina.id, beatriz.id])
        try await repo.like(marina.id)
        try await repo.like(beatriz.id)
        _ = try await repo.createGroup(named: "Grupo", with: [marina.id])
        let model = ChatListViewModel(repository: repo)

        await model.load()

        // O grupo não vira contato, e ninguém aparece duas vezes.
        #expect(Set(model.contacts.map(\.id)) == [marina.id, beatriz.id])
        #expect(model.contacts.count == 2)
    }

    @Test("Criar grupo devolve o grupo pronto para abrir")
    func createGroupReturnsSummary() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina.id])
        try await repo.like(marina.id)
        let model = ChatListViewModel(repository: repo)
        await model.load()

        let grupo = await model.createGroup(named: "Corrida", with: [marina.id])

        #expect(grupo?.title == "Corrida")
        #expect(grupo?.others.map(\.id) == [marina.id])
        #expect(model.conversations.value?.count == 2)
    }

    @Test("Grupo sem nome avisa em vez de criar")
    func groupWithoutNameWarns() async {
        let model = ChatListViewModel(repository: InMemoryChatRepository())
        await model.load()

        let grupo = await model.createGroup(named: "  ", with: [])

        #expect(grupo == nil)
        #expect(model.toastMessage == "Dê um nome ao grupo.")
    }

    @Test("Abrir o link mostra o grupo antes de entrar")
    func openingLinkPreviewsFirst() async throws {
        let grupo = try Conversation.group(named: "Pedal", createdBy: rafael.id, members: [])
        let link = GroupInviteLink(conversationID: grupo.id)
        let repo = InMemoryChatRepository(conversations: [grupo], links: [link])
        let model = ChatListViewModel(repository: repo)
        await model.load()

        await model.openInviteLink(token: link.token)

        #expect(model.groupPreview?.title == "Pedal")
        #expect(model.groupPreview?.others.map(\.name) == ["Rafael"])
        // Ver não é entrar.
        #expect(model.conversations.value?.isEmpty == true)
    }

    @Test("Entrar pela prévia põe o grupo na lista")
    func joiningFromPreview() async throws {
        let grupo = try Conversation.group(named: "Pedal", createdBy: rafael.id, members: [])
        let link = GroupInviteLink(conversationID: grupo.id)
        let model = ChatListViewModel(repository: InMemoryChatRepository(
            conversations: [grupo],
            links: [link]
        ))
        await model.openInviteLink(token: link.token)

        let entrei = await model.joinPreviewedGroup(token: link.token)

        #expect(entrei?.id == grupo.id)
        #expect(model.groupPreview == nil)
        #expect(model.conversations.value?.map(\.id) == [grupo.id])
    }

    @Test("Link vencido explica em vez de abrir prévia")
    func expiredLinkExplains() async throws {
        let criado = Date(timeIntervalSince1970: 1_000_000)
        let grupo = try Conversation.group(named: "Pedal", createdBy: rafael.id, members: [])
        let link = GroupInviteLink(conversationID: grupo.id, createdAt: criado, lifetime: 60)
        let repo = InMemoryChatRepository(
            conversations: [grupo],
            links: [link],
            now: { criado.addingTimeInterval(120) }
        )
        let model = ChatListViewModel(repository: repo)

        await model.openInviteLink(token: link.token)

        #expect(model.groupPreview == nil)
        #expect(model.toastMessage == "Esse link de grupo venceu. Peça um novo.")
    }

    @Test("Abrir o link de um grupo onde já estou não mostra prévia")
    func alreadyMemberSkipsPreview() async throws {
        let repo = InMemoryChatRepository()
        let grupo = try await repo.createGroup(named: "Corrida", with: [])
        let link = try await repo.createInviteLink(for: grupo.id)
        let model = ChatListViewModel(repository: repo)

        await model.openInviteLink(token: link.token)

        #expect(model.groupPreview == nil)
        #expect(model.toastMessage == "Você já está em Corrida.")
    }
}

@MainActor
@Suite("Chat · Conversa")
struct ConversationViewModelTests {
    private let marina = SampleData.partners[0]

    private func comConversa() async throws -> (ConversationViewModel, InMemoryChatRepository) {
        let repo = InMemoryChatRepository(likedMeBy: [marina.id])
        try await repo.like(marina.id)
        let resumo = try #require(try await repo.summaries().first)
        return (ConversationViewModel(
            summary: resumo,
            repository: repo,
            invites: InMemoryWorkoutRepository(),
            workouts: InMemoryWorkoutRepository()
        ), repo)
    }

    @Test("Enviar põe a mensagem na tela e limpa o campo")
    func sendAppendsAndClears() async throws {
        let (model, _) = try await comConversa()
        await model.load()
        model.draft = "bora amanhã às 7?"

        await model.send()

        #expect(model.draft.isEmpty)
        #expect(model.messages.map(\.content) == [.text("bora amanhã às 7?")])
        #expect(model.messages.first.map(model.isMine) == true)
    }

    @Test("Campo em branco não envia", arguments: ["", "   ", "\n"])
    func blankDraftDoesNotSend(texto: String) async throws {
        let (model, _) = try await comConversa()
        model.draft = texto

        await model.send()

        #expect(!model.canSend)
        #expect(model.messages.isEmpty)
    }

    @Test("Conversa privada não tem link de convite")
    func directHasNoLinkControls() async throws {
        let (model, _) = try await comConversa()
        #expect(!model.canManageLink)
    }

    @Test("Quem criou o grupo gera e desativa o link")
    func creatorManagesLink() async throws {
        let repo = InMemoryChatRepository()
        _ = try await repo.createGroup(named: "Corrida", with: [])
        let resumo = try #require(try await repo.summaries().first)
        let model = ConversationViewModel(
            summary: resumo,
            repository: repo,
            invites: InMemoryWorkoutRepository(),
            workouts: InMemoryWorkoutRepository()
        )
        await model.load()
        #expect(model.canManageLink)
        #expect(model.inviteLink == nil)

        await model.createInviteLink()
        let token = try #require(model.inviteLink?.token)

        await model.revokeInviteLink()
        #expect(model.inviteLink == nil)
        await #expect(throws: ConversationError.linkRevoked) {
            try await repo.joinGroup(withToken: token)
        }
    }

    @Test("Ao reabrir o grupo, o link que vale continua lá")
    func linkSurvivesReopening() async throws {
        let repo = InMemoryChatRepository()
        let grupo = try await repo.createGroup(named: "Corrida", with: [])
        let link = try await repo.createInviteLink(for: grupo.id)
        let resumo = try #require(try await repo.summaries().first)
        let model = ConversationViewModel(
            summary: resumo,
            repository: repo,
            invites: InMemoryWorkoutRepository(),
            workouts: InMemoryWorkoutRepository()
        )

        await model.load()

        #expect(model.inviteLink?.token == link.token)
    }
}
