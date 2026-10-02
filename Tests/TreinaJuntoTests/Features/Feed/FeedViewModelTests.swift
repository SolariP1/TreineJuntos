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
    /// Treinos e convites vêm do mesmo ator, como no app.
    private func makeModel(
        partners: PartnerRepository = InMemoryPartnerRepository(),
        workouts: InMemoryWorkoutRepository = SampleData.seededWorkoutRepository(),
        chat: ChatRepository = SampleData.seededChatRepository()
    ) -> FeedViewModel {
        FeedViewModel(
            partnerRepository: partners,
            inviteRepository: workouts,
            workoutRepository: workouts,
            chatRepository: chat
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

    // MARK: - Curtir

    @Test("Curtir de um lado só marca a pessoa e não abre conversa")
    func oneSidedLike() async throws {
        let chat = InMemoryChatRepository()
        let model = makeModel(chat: chat)
        await model.load()
        let marina = try #require(model.partners.value?.first)

        await model.like(marina)

        #expect(model.hasLiked(marina))
        #expect(model.toastMessage == "Você curtiu Marina.")
        #expect(try await chat.conversations().isEmpty)
    }

    @Test("Curtida mútua avisa que a conversa está no Chat")
    func mutualLikeOpensChat() async throws {
        let marina = SampleData.partners[0]
        let chat = InMemoryChatRepository(likedMeBy: [marina.id])
        let model = makeModel(chat: chat)
        await model.load()

        await model.like(marina)

        #expect(model.toastMessage?.contains("Vocês se curtiram") == true)
        #expect(try await chat.conversations().count == 1)
    }

    @Test("Tocar duas vezes em curtir não faz nada a mais")
    func doubleLikeIsIgnored() async throws {
        let model = makeModel(chat: InMemoryChatRepository())
        await model.load()
        let marina = try #require(model.partners.value?.first)

        await model.like(marina)
        model.toastMessage = nil
        await model.like(marina)

        #expect(model.hasLiked(marina))
        #expect(model.toastMessage == nil)
    }

    // MARK: - Convidar pela vaga

    @Test("Convidar pela vaga manda o convite como mensagem na conversa")
    func slotInviteSendsMessage() async throws {
        let marina = SampleData.partners[0]
        let chat = InMemoryChatRepository(likedMeBy: [marina.id])
        try await chat.like(marina.id)
        let treinos = InMemoryWorkoutRepository()
        let model = makeModel(workouts: treinos, chat: chat)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 3, when: "Agora", gym: nil)
        await model.loadInviteTargets()
        let conversa = try #require(model.inviteTargets.first)

        await model.inviteToActiveWorkout(conversa)

        #expect(model.toastMessage == "Convite enviado para Marina!")
        let mensagens = try await chat.messages(in: conversa.id)
        #expect(try mensagens.last?.content == .workoutInvite(workoutID: #require(model.activeWorkout?.id)))
    }

    @Test("Convidar a mesma conversa duas vezes avisa em vez de repetir")
    func slotInviteTwiceWarns() async throws {
        let marina = SampleData.partners[0]
        let chat = InMemoryChatRepository(likedMeBy: [marina.id])
        try await chat.like(marina.id)
        let model = makeModel(workouts: InMemoryWorkoutRepository(), chat: chat)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 3, when: "Agora", gym: nil)
        await model.loadInviteTargets()
        let conversa = try #require(model.inviteTargets.first)

        await model.inviteToActiveWorkout(conversa)
        await model.inviteToActiveWorkout(conversa)

        #expect(model.toastMessage == "Marina já tem convite para este treino.")
        #expect(try await chat.messages(in: conversa.id).count == 1)
    }

    @Test("O rosto de quem entrou vem dos parceiros conhecidos")
    func partnerFaceLookup() async {
        let model = makeModel()
        await model.load()
        let marina = SampleData.partners[0]

        #expect(model.partner(withID: marina.id)?.name == "Marina")
        #expect(model.partner(withID: UUID()) == nil)
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

    @Test("Aceitar um convite põe você no treino de quem chamou")
    func acceptingPutsYouInTheirWorkout() async throws {
        let model = makeModel()
        await model.load()
        let recebido = try #require(model.invites.first)

        await model.respond(to: recebido, accepted: true)

        #expect(model.activeWorkout?.id == recebido.workout.id)
        #expect(model.activeWorkout?.contains(SampleData.meID) == true)
    }

    @Test("Recusar não põe você em treino nenhum")
    func decliningPutsYouNowhere() async throws {
        let model = makeModel()
        await model.load()
        let recebido = try #require(model.invites.first)

        await model.respond(to: recebido, accepted: false)

        #expect(model.activeWorkout == nil)
    }

    @Test("Sair de um treino dos outros não cancela o treino deles")
    func leavingSomeoneElsesWorkoutDoesNotCancelIt() async throws {
        // Antes isto cancelava o treino do anfitrião, e as outras pessoas
        // ficavam sem treino sem entender por quê.
        let repo = SampleData.seededWorkoutRepository()
        let model = makeModel(workouts: repo)
        await model.load()
        let recebido = try #require(model.invites.first)
        await model.respond(to: recebido, accepted: true)

        await model.leaveOrCancelActiveWorkout()

        #expect(model.activeWorkout == nil)
        // O treino do anfitrião segue aberto para quem ficou.
        let aindaAberto = try await repo.nearbyOpenWorkouts(withinMeters: 5000)
        #expect(aindaAberto.contains { $0.id == recebido.workout.id })
    }

    @Test("Abrir com um treino já de pé mostra o treino em vez de deixar sem saída")
    func openingWithAnActiveWorkoutShowsIt() async throws {
        // Se a tela e o repositório discordarem, a pessoa não pode ficar
        // presa: o app mostra o treino que existe de verdade.
        let treino = try Workout(hostID: SampleData.meID, sport: .corrida)
        let repo = InMemoryWorkoutRepository(workouts: [treino])
        let model = makeModel(workouts: repo)

        await model.openWorkout(sport: .yoga, size: 2, when: "Agora", gym: nil)

        #expect(model.activeWorkout?.id == treino.id)
        #expect(model.toastMessage?.contains("já tem um treino") == true)
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

    @Test("Começar move o treino para iniciado, com hora marcada")
    func startingMovesToStarted() async {
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        await model.startActiveWorkout(usingGymInvites: false)

        #expect(model.activeWorkout?.status == .started)
        #expect(model.activeWorkout?.startedAt != nil)
    }

    @Test("Começar sem convite não mexe no saldo")
    func startingWithoutInvitesKeepsBalance() async {
        let model = makeModel(workouts: InMemoryWorkoutRepository(invitesPerMonth: 4))
        await model.load()
        await model.openWorkout(sport: .corrida, size: 3, when: "Agora", gym: "Smart Fit")

        await model.startActiveWorkout(usingGymInvites: false)

        #expect(model.inviteBalance.available() == 4)
    }

    @Test("Saldo insuficiente avisa quanto falta, em vez de falhar calado")
    func insufficientBalanceSaysHowManyAreMissing() async throws {
        var treino = try Workout(
            hostID: SampleData.meID, sport: .corrida, gym: "Smart Fit", maxParticipants: 3
        )
        try treino.join(UUID())
        try treino.join(UUID())
        let model = makeModel(
            workouts: InMemoryWorkoutRepository(invitesPerMonth: 1, workouts: [treino])
        )
        await model.load()

        await model.startActiveWorkout(usingGymInvites: true)

        #expect(model.toastMessage?.contains("2 convites") == true)
        #expect(model.activeWorkout?.status == .open, "tem que continuar aberto para ajustar")
    }

    @Test("Encerrar tira o treino do Feed")
    func finishingClearsTheWorkout() async {
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        await model.startActiveWorkout(usingGymInvites: false)

        await model.finishActiveWorkout(present: [SampleData.meID])

        #expect(model.activeWorkout == nil)
    }

    @Test("Encerrar libera para abrir outro treino")
    func finishingFreesTheSlot() async {
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        await model.startActiveWorkout(usingGymInvites: false)
        await model.finishActiveWorkout(present: [SampleData.meID])

        await model.openWorkout(sport: .yoga, size: 2, when: "Agora", gym: nil)

        #expect(model.activeWorkout?.sport == .yoga)
    }

    @Test("Cancelar tira o treino do Feed")
    func cancellingClearsTheWorkout() async {
        let model = makeModel()
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        await model.leaveOrCancelActiveWorkout()

        #expect(model.activeWorkout == nil)
    }
}
