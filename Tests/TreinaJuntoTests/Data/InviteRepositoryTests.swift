import Testing
@testable import TreinaJunto

@Suite("Dados · Repositório de convites")
struct InviteRepositoryTests {
    @Test("Convidar alguém marca a pessoa como convidada")
    func invitingMarksThePartner() async throws {
        let repo = InMemoryInviteRepository()
        let parceiro = Fixtures.partner()

        try await repo.invite(partnerID: parceiro.id)

        #expect(await repo.hasInvited(parceiro.id))
    }

    @Test("Não dá para convidar a mesma pessoa duas vezes")
    func cannotInviteTwice() async throws {
        // Esta regra vivia num `guard` dentro do FeedView, fora do alcance
        // de qualquer teste. É o motivo de a camada existir.
        let repo = InMemoryInviteRepository()
        let parceiro = Fixtures.partner()

        try await repo.invite(partnerID: parceiro.id)

        await #expect(throws: InviteError.alreadyInvited) {
            try await repo.invite(partnerID: parceiro.id)
        }
    }

    @Test("Convidar uma pessoa não afeta as outras")
    func invitingOneDoesNotBlockAnother() async throws {
        let repo = InMemoryInviteRepository()
        let marina = Fixtures.partner(name: "Marina")
        let beatriz = Fixtures.partner(name: "Beatriz")

        try await repo.invite(partnerID: marina.id)
        try await repo.invite(partnerID: beatriz.id)

        #expect(await repo.hasInvited(marina.id))
        #expect(await repo.hasInvited(beatriz.id))
    }

    @Test("Responder a um convite tira ele da lista de pendentes", arguments: [true, false])
    func respondingRemovesFromPending(accepted: Bool) async throws {
        let repo = InMemoryInviteRepository()
        let pendentes = try await repo.pendingInvites()
        let primeiro = try #require(pendentes.first)

        try await repo.respond(to: primeiro.id, accepted: accepted)

        let restantes = try await repo.pendingInvites()
        #expect(restantes.count == pendentes.count - 1)
        #expect(!restantes.contains { $0.id == primeiro.id })
    }

    @Test("Responder duas vezes ao mesmo convite falha")
    func respondingTwiceFails() async throws {
        let repo = InMemoryInviteRepository()
        let primeiro = try #require(try await repo.pendingInvites().first)

        try await repo.respond(to: primeiro.id, accepted: true)

        await #expect(throws: InviteError.inviteNotFound) {
            try await repo.respond(to: primeiro.id, accepted: true)
        }
    }
}
