import Foundation
import Testing
@testable import TreinaJunto

/// Repositório que sempre falha, para exercitar o caminho de erro — que só
/// passou a existir quando os dados deixaram de ser constante no código.
private struct FailingPartnerRepository: PartnerRepository {
    func nearbyPartners(withinMeters _: Int) async throws -> [WorkoutPartner] {
        throw PartnerError.notFound
    }

    func portfolio(for _: UUID) async throws -> PartnerPortfolio {
        throw PartnerError.notFound
    }
}

@MainActor
@Suite("Feed · ViewModel")
struct FeedViewModelTests {
    private func makeModel(
        partners: PartnerRepository = InMemoryPartnerRepository(),
        invites: InviteRepository = InMemoryInviteRepository(),
        workouts: WorkoutRepository = InMemoryWorkoutRepository()
    ) -> FeedViewModel {
        FeedViewModel(
            partnerRepository: partners,
            inviteRepository: invites,
            workoutRepository: workouts
        )
    }

    @Test("Começa parado, sem ter pedido nada")
    func startsIdle() {
        let model = makeModel()
        #expect(model.partners.value == nil)
        #expect(model.invites.isEmpty)
    }

    @Test("Carregar traz parceiros e convites")
    func loadFetchesBoth() async {
        let model = makeModel()

        await model.load()

        #expect(model.partners.value?.isEmpty == false)
        #expect(!model.invites.isEmpty)
    }

    @Test("Quando o repositório falha, a tela mostra erro em vez de lista vazia")
    func loadFailureSurfacesAnError() async {
        let model = makeModel(partners: FailingPartnerRepository())

        await model.load()

        #expect(model.partners.errorMessage != nil)
        #expect(model.partners.value == nil)
    }

    @Test("Convidar marca a pessoa e avisa na tela")
    func invitingMarksAndToasts() async throws {
        let model = makeModel()
        await model.load()
        let marina = try #require(model.partners.value?.first)

        await model.invite(marina)

        #expect(model.hasInvited(marina))
        #expect(model.toastMessage?.contains(marina.name) == true)
    }

    @Test("Tocar duas vezes em convidar não desfaz o convite")
    func doubleTapKeepsTheInvite() async throws {
        // O repositório recusa o segundo convite; a tela precisa continuar
        // mostrando a pessoa como convidada, não voltar atrás.
        let model = makeModel()
        await model.load()
        let marina = try #require(model.partners.value?.first)

        await model.invite(marina)
        await model.invite(marina)

        #expect(model.hasInvited(marina))
    }

    @Test("Responder tira o convite da lista", arguments: [true, false])
    func respondingRemovesTheInvite(accepted: Bool) async throws {
        let model = makeModel()
        await model.load()
        let primeiro = try #require(model.invites.first)
        let antes = model.invites.count

        await model.respond(to: primeiro, accepted: accepted)

        #expect(model.invites.count == antes - 1)
        #expect(!model.invites.contains { $0.id == primeiro.id })
    }

    @Test("Abrir treino usa o nome do esporte, não o do case")
    func openWorkoutToastUsesTheLabel() async {
        // Regressão da fase 2: interpolar o enum direto imprimia "musculacao",
        // sem acento e em minúscula.
        let model = makeModel()

        await model.openWorkout(sport: .musculacao, size: 2, when: "Agora", gym: nil)

        #expect(model.toastMessage?.contains("Musculação") == true)
        #expect(model.toastMessage?.contains("musculacao") == false)
    }

    @Test("Abrir treino põe o treino no Feed")
    func openingPutsTheWorkoutOnTheFeed() async {
        let model = makeModel()
        await model.load()

        await model.openWorkout(sport: .corrida, size: 4, when: "Agora", gym: nil)

        #expect(model.activeWorkout?.maxParticipants == 4)
        #expect(model.activeWorkout?.isParty == true)
    }

    @Test("Não dá para ter dois treinos abertos ao mesmo tempo")
    func cannotOpenTwoWorkouts() async {
        // Dois de pé deixariam a Live Activity sem saber qual mostrar.
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        let primeiro = model.activeWorkout?.id

        await model.openWorkout(sport: .yoga, size: 2, when: "Agora", gym: nil)

        #expect(model.activeWorkout?.id == primeiro)
        #expect(model.toastMessage?.contains("já tem um treino aberto") == true)
    }

    @Test("Cancelar tira o treino do Feed")
    func cancellingClearsTheWorkout() async {
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        await model.cancelActiveWorkout()

        #expect(model.activeWorkout == nil)
    }
}
