import Foundation
import Testing
@testable import TreinaJunto

@Suite("Dados · Chat")
struct ChatRepositoryTests {
    private let marina = SampleData.partners[0].id
    private let beatriz = SampleData.partners[2].id
    private let rafael = SampleData.partners[3].id

    // MARK: - Curtida

    @Test("Curtida de um lado só não abre conversa")
    func oneSidedLikeOpensNothing() async throws {
        let repo = InMemoryChatRepository()

        let conversa = try await repo.like(marina)

        #expect(conversa == nil)
        #expect(try await repo.conversations().isEmpty)
    }

    @Test("Curtida mútua abre a conversa privada")
    func mutualLikeOpensDirectConversation() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])

        let conversa = try #require(try await repo.like(marina))

        #expect(conversa.kind == .direct)
        #expect(conversa.contains(SampleData.meID))
        #expect(conversa.contains(marina))
    }

    @Test("A curtida que chega depois da minha também abre a conversa")
    func likeArrivingLaterOpensConversation() async throws {
        let repo = InMemoryChatRepository()
        try await repo.like(beatriz)

        let conversa = try await repo.receiveLike(from: beatriz)

        #expect(conversa != nil)
        #expect(try await repo.conversations().count == 1)
    }

    @Test("Curtir de novo não abre uma segunda conversa")
    func likingAgainDoesNotDuplicate() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])

        let primeira = try await repo.like(marina)
        let segunda = try await repo.like(marina)
        try await repo.receiveLike(from: marina)

        #expect(primeira?.id == segunda?.id)
        #expect(try await repo.conversations().count == 1)
    }

    // MARK: - Mensagens

    @Test("Mensagem enviada aparece na conversa, sem espaço sobrando")
    func sentMessageAppears() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])
        let conversa = try #require(try await repo.like(marina))

        try await repo.send(.text("  bora amanhã?  "), to: conversa.id)

        let mensagens = try await repo.messages(in: conversa.id)
        #expect(mensagens.map(\.content) == [.text("bora amanhã?")])
        #expect(mensagens.first?.authorID == SampleData.meID)
    }

    @Test("Mensagem vazia é recusada", arguments: ["", "   ", "\n\n"])
    func emptyMessageIsRejected(texto: String) async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])
        let conversa = try #require(try await repo.like(marina))

        await #expect(throws: ConversationError.emptyMessage) {
            try await repo.send(.text(texto), to: conversa.id)
        }
    }

    @Test("Não leio nem escrevo numa conversa da qual não faço parte")
    func outsidersCannotReadOrWrite() async throws {
        let alheia = try Conversation.direct(between: marina, and: beatriz)
        let repo = InMemoryChatRepository(conversations: [alheia])

        await #expect(throws: ConversationError.notAMember) {
            try await repo.messages(in: alheia.id)
        }
        await #expect(throws: ConversationError.notAMember) {
            try await repo.send(.text("oi"), to: alheia.id)
        }
        #expect(try await repo.conversations().isEmpty)
    }

    @Test("A conversa com mensagem mais recente vem primeiro")
    func conversationsSortedByLastActivity() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina, beatriz])
        let comMarina = try #require(try await repo.like(marina))
        let comBeatriz = try #require(try await repo.like(beatriz))

        try await repo.send(.text("oi"), to: comMarina.id)

        #expect(try await repo.conversations().map(\.id) == [comMarina.id, comBeatriz.id])
    }

    // MARK: - Grupos

    @Test("Crio grupo com quem já tenho conversa")
    func createGroupWithMyContacts() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina, beatriz])
        try await repo.like(marina)
        try await repo.like(beatriz)

        let grupo = try await repo.createGroup(named: "Corrida de sábado", with: [marina, beatriz])

        #expect(grupo.memberIDs == [SampleData.meID, marina, beatriz])
        #expect(try await repo.conversations().contains { $0.id == grupo.id })
    }

    @Test("Não chamo para o grupo quem não está nas minhas conversas")
    func cannotAddStrangersToGroup() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])
        try await repo.like(marina)

        await #expect(throws: ConversationError.notInMyConversations) {
            try await repo.createGroup(named: "Corrida", with: [marina, rafael])
        }
    }

    // MARK: - Link

    @Test("Entro no grupo pelo link")
    func joinGroupWithLink() async throws {
        let grupo = try Conversation.group(named: "Pedal", createdBy: rafael, members: [])
        let link = GroupInviteLink(conversationID: grupo.id)
        let repo = InMemoryChatRepository(conversations: [grupo], links: [link])

        let entrei = try await repo.joinGroup(withToken: link.token)

        #expect(entrei.contains(SampleData.meID))
        #expect(try await repo.conversations().map(\.id) == [grupo.id])
    }

    @Test("Link vencido não põe ninguém no grupo")
    func expiredLinkIsRefused() async throws {
        let criado = Date(timeIntervalSince1970: 1_000_000)
        let grupo = try Conversation.group(named: "Pedal", createdBy: rafael, members: [])
        let link = GroupInviteLink(conversationID: grupo.id, createdAt: criado, lifetime: 60)
        let repo = InMemoryChatRepository(
            conversations: [grupo],
            links: [link],
            now: { criado.addingTimeInterval(61) }
        )

        await #expect(throws: ConversationError.linkExpired) {
            try await repo.joinGroup(withToken: link.token)
        }
    }

    @Test("Link desconhecido é recusado")
    func unknownLinkIsRefused() async {
        let repo = InMemoryChatRepository()

        await #expect(throws: ConversationError.linkNotFound) {
            try await repo.joinGroup(withToken: "nao-existe")
        }
    }

    @Test("Revogar derruba o link na hora")
    func revokedLinkIsRefused() async throws {
        let repo = InMemoryChatRepository()
        let grupo = try await repo.createGroup(named: "Corrida", with: [])
        let link = try await repo.createInviteLink(for: grupo.id)

        try await repo.revokeInviteLink(for: grupo.id)

        await #expect(throws: ConversationError.linkRevoked) {
            try await repo.joinGroup(withToken: link.token)
        }
    }

    @Test("Gerar link novo invalida o anterior")
    func newLinkReplacesOld() async throws {
        let repo = InMemoryChatRepository()
        let grupo = try await repo.createGroup(named: "Corrida", with: [])
        let antigo = try await repo.createInviteLink(for: grupo.id)

        _ = try await repo.createInviteLink(for: grupo.id)

        await #expect(throws: ConversationError.linkNotFound) {
            try await repo.joinGroup(withToken: antigo.token)
        }
    }

    @Test("Só quem criou o grupo gera link")
    func onlyCreatorMakesLinks() async throws {
        var grupo = try Conversation.group(named: "Pedal", createdBy: rafael, members: [])
        try grupo.add(SampleData.meID)
        let repo = InMemoryChatRepository(conversations: [grupo])

        await #expect(throws: ConversationError.notGroupCreator) {
            try await repo.createInviteLink(for: grupo.id)
        }
    }

    @Test("Conversa privada não tem link")
    func directHasNoLink() async throws {
        let repo = InMemoryChatRepository(likedMeBy: [marina])
        let conversa = try #require(try await repo.like(marina))

        await #expect(throws: ConversationError.directIsAlwaysTwo) {
            try await repo.createInviteLink(for: conversa.id)
        }
    }

    @Test("O chat de exemplo nasce com a conversa da Marina")
    func seededChatHasMarina() async throws {
        let repo = SampleData.seededChatRepository()
        let conversas = try await repo.conversations()

        #expect(conversas.count == 1)
        #expect(conversas.first?.contains(marina) == true)
        // O Rafael me curtiu: curtir de volta abre a segunda conversa.
        #expect(try await repo.like(rafael) != nil)
    }
}
