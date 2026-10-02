import Foundation
import Testing
@testable import TreinaJunto

@Suite("Domínio · Conversa")
struct ConversationTests {
    private let eu = UUID()
    private let marina = UUID()
    private let beatriz = UUID()

    @Test("Conversa privada é de duas pessoas")
    func directHasTwoMembers() throws {
        let conversa = try Conversation.direct(between: eu, and: marina)

        #expect(conversa.kind == .direct)
        #expect(conversa.memberIDs == [eu, marina])
        #expect(conversa.otherMember(than: eu) == marina)
    }

    @Test("Ninguém conversa consigo mesmo")
    func cannotTalkToYourself() {
        #expect(throws: ConversationError.cannotTalkToYourself) {
            try Conversation.direct(between: eu, and: eu)
        }
    }

    @Test("Conversa privada não recebe terceira pessoa")
    func directIsAlwaysTwo() throws {
        var conversa = try Conversation.direct(between: eu, and: marina)

        #expect(throws: ConversationError.directIsAlwaysTwo) {
            try conversa.add(beatriz)
        }
    }

    @Test("Quem cria o grupo já entra, sem repetir ninguém")
    func groupIncludesCreatorOnce() throws {
        let grupo = try Conversation.group(named: "Corrida", createdBy: eu, members: [marina, eu, marina])

        #expect(grupo.kind == .group)
        #expect(grupo.memberIDs == [eu, marina])
        #expect(grupo.createdBy == eu)
    }

    @Test("Grupo precisa de nome", arguments: ["", "   ", "\n"])
    func groupNeedsAName(nome: String) {
        #expect(throws: ConversationError.groupNeedsAName) {
            try Conversation.group(named: nome, createdBy: eu, members: [])
        }
    }

    @Test("Nome do grupo sai sem espaço sobrando")
    func groupNameIsTrimmed() throws {
        let grupo = try Conversation.group(named: "  Pedal  ", createdBy: eu, members: [])
        #expect(grupo.name == "Pedal")
    }

    @Test("Entrar duas vezes no grupo é recusado")
    func cannotJoinTwice() throws {
        var grupo = try Conversation.group(named: "Corrida", createdBy: eu, members: [marina])

        #expect(throws: ConversationError.alreadyMember) {
            try grupo.add(marina)
        }
    }
}

@Suite("Domínio · Link de grupo")
struct GroupInviteLinkTests {
    private let agora = Date(timeIntervalSince1970: 1_000_000)

    @Test("Link novo vale")
    func freshLinkIsValid() throws {
        let link = GroupInviteLink(conversationID: UUID(), createdAt: agora)
        try link.validate(now: agora.addingTimeInterval(60))
    }

    @Test("Link vence depois da validade")
    func linkExpires() {
        let link = GroupInviteLink(conversationID: UUID(), createdAt: agora, lifetime: 3600)

        #expect(throws: ConversationError.linkExpired) {
            try link.validate(now: agora.addingTimeInterval(3600))
        }
    }

    @Test("Link revogado não vale, mesmo dentro da validade")
    func revokedLinkIsInvalid() {
        var link = GroupInviteLink(conversationID: UUID(), createdAt: agora)
        link.revoke(now: agora)

        #expect(throws: ConversationError.linkRevoked) {
            try link.validate(now: agora)
        }
    }

    @Test("Tokens não se repetem")
    func tokensAreUnique() {
        let tokens = Set((0 ..< 200).map { _ in GroupInviteLink.makeToken() })
        #expect(tokens.count == 200)
    }

    @Test("O link abre o app no grupo")
    func linkURLUsesAppScheme() {
        let link = GroupInviteLink(token: "abc", conversationID: UUID())
        #expect(link.url?.absoluteString == "treinajunto://grupo/abc")
    }
}
