import Foundation
import Testing
@testable import TreinaJunto

@Suite("Dados · Convites de treino")
struct InviteRepositoryTests {
    private let marina = SampleData.partners[0]
    private let beatriz = SampleData.partners[2]

    /// Repositório com um treino meu aberto e ninguém convidado ainda.
    private func comMeuTreinoAberto(tamanho: Int = 3) throws -> (InMemoryWorkoutRepository, Workout) {
        let treino = try Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: tamanho)
        return (InMemoryWorkoutRepository(workouts: [treino]), treino)
    }

    /// Repositório com um treino de outra pessoa, que me convidou.
    private func comConviteParaMim() throws -> (InMemoryWorkoutRepository, WorkoutInvite) {
        let treino = try Workout(hostID: marina.id, sport: .corrida, maxParticipants: 2)
        let convite = WorkoutInvite(
            workoutID: treino.id,
            fromProfileID: marina.id,
            toProfileID: SampleData.meID
        )
        return (InMemoryWorkoutRepository(workouts: [treino], invites: [convite]), convite)
    }

    // MARK: - Convidar

    @Test("Convidar alguém para o meu treino cria um convite")
    func invitingCreatesAnInvite() async throws {
        let (repo, treino) = try comMeuTreinoAberto()

        try await repo.invite(partnerID: marina.id, toWorkout: treino.id)

        // O convite é meu, então não aparece na minha caixa de entrada.
        #expect(try await repo.receivedInvites().isEmpty)
    }

    @Test("Não dá para convidar a mesma pessoa duas vezes para o mesmo treino")
    func cannotInviteTwiceToTheSameWorkout() async throws {
        let (repo, treino) = try comMeuTreinoAberto()
        try await repo.invite(partnerID: marina.id, toWorkout: treino.id)

        await #expect(throws: InviteError.alreadyInvited) {
            try await repo.invite(partnerID: marina.id, toWorkout: treino.id)
        }
    }

    @Test("Não dá para convidar para o treino dos outros")
    func cannotInviteToSomeoneElsesWorkout() async throws {
        let (repo, convite) = try comConviteParaMim()

        await #expect(throws: InviteError.notMyWorkout) {
            try await repo.invite(partnerID: beatriz.id, toWorkout: convite.workoutID)
        }
    }

    @Test("Treino que já começou não recebe convite")
    func startedWorkoutTakesNoInvites() async throws {
        let (repo, treino) = try comMeuTreinoAberto()
        try await repo.start(workoutID: treino.id, usingGymInvites: false)

        await #expect(throws: InviteError.workoutNotOpen) {
            try await repo.invite(partnerID: marina.id, toWorkout: treino.id)
        }
    }

    @Test("Treino cheio não recebe convite")
    func fullWorkoutTakesNoInvites() async throws {
        var treino = try Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: 2)
        try treino.join(beatriz.id)
        let repo = InMemoryWorkoutRepository(workouts: [treino])

        await #expect(throws: WorkoutError.full) {
            try await repo.invite(partnerID: marina.id, toWorkout: treino.id)
        }
    }

    // MARK: - Receber e responder

    @Test("O convite recebido vem com quem chamou e para qual treino")
    func receivedInviteCarriesItsContext() async throws {
        let (repo, _) = try comConviteParaMim()

        let recebido = try #require(try await repo.receivedInvites().first)

        #expect(recebido.from.name == marina.name)
        #expect(recebido.workout.sport == .corrida)
    }

    @Test("Aceitar põe a pessoa dentro do treino")
    func acceptingJoinsTheWorkout() async throws {
        // É o ponto da mudança inteira: antes o convite aceito não levava a
        // lugar nenhum.
        let (repo, convite) = try comConviteParaMim()

        try await repo.respond(to: convite.id, accepted: true)

        let meuTreino = try #require(try await repo.activeWorkout())
        #expect(meuTreino.id == convite.workoutID)
        #expect(meuTreino.contains(SampleData.meID))
    }

    @Test("Recusar não entra em treino nenhum")
    func decliningJoinsNothing() async throws {
        let (repo, convite) = try comConviteParaMim()

        try await repo.respond(to: convite.id, accepted: false)

        #expect(try await repo.activeWorkout() == nil)
    }

    @Test("Responder tira o convite da caixa de entrada", arguments: [true, false])
    func respondingClearsTheInbox(accepted: Bool) async throws {
        let (repo, convite) = try comConviteParaMim()

        try await repo.respond(to: convite.id, accepted: accepted)

        #expect(try await repo.receivedInvites().isEmpty)
    }

    @Test("Responder duas vezes ao mesmo convite falha")
    func respondingTwiceFails() async throws {
        let (repo, convite) = try comConviteParaMim()
        try await repo.respond(to: convite.id, accepted: false)

        await #expect(throws: InviteError.alreadyAnswered) {
            try await repo.respond(to: convite.id, accepted: false)
        }
    }

    @Test("Se o treino encheu enquanto o convite esperava, aceitar falha")
    func acceptingAFullWorkoutFails() async throws {
        // O convite não pode virar aceito no vazio: a pessoa apareceria como
        // combinada sem estar no treino.
        var treino = try Workout(hostID: marina.id, sport: .corrida, maxParticipants: 2)
        try treino.join(beatriz.id)
        let convite = WorkoutInvite(
            workoutID: treino.id,
            fromProfileID: marina.id,
            toProfileID: SampleData.meID
        )
        let repo = InMemoryWorkoutRepository(workouts: [treino], invites: [convite])

        await #expect(throws: WorkoutError.full) {
            try await repo.respond(to: convite.id, accepted: true)
        }
        #expect(try await repo.activeWorkout() == nil)
    }

    // MARK: - Aceites ainda não vistos

    /// Meu treino, com um convite que a Marina já respondeu.
    private func comMinhaMarinaRespondendo(
        accepted: Bool,
        seen: Bool = false
    ) throws -> (InMemoryWorkoutRepository, WorkoutInvite) {
        let treino = try Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: 3)
        let convite = WorkoutInvite(
            workoutID: treino.id,
            fromProfileID: SampleData.meID,
            toProfileID: marina.id,
            status: accepted ? .accepted : .declined,
            respondedAt: Date(),
            acceptanceSeen: seen
        )
        return (InMemoryWorkoutRepository(workouts: [treino], invites: [convite]), convite)
    }

    @Test("Quem convidou vê o aceite como novidade")
    func inviterSeesTheAcceptance() async throws {
        let (repo, _) = try comMinhaMarinaRespondendo(accepted: true)

        let novidades = try await repo.unseenAcceptances()

        #expect(novidades.count == 1)
        #expect(novidades.first?.from.name == marina.name)
    }

    @Test("Novidade marcada como vista não volta")
    func seenAcceptanceDoesNotComeBack() async throws {
        let (repo, convite) = try comMinhaMarinaRespondendo(accepted: true)

        try await repo.markAcceptancesSeen([convite.id])

        #expect(try await repo.unseenAcceptances().isEmpty)
    }

    @Test("Aceite já visto não aparece de novo ao reabrir")
    func alreadySeenStaysSeen() async throws {
        let (repo, _) = try comMinhaMarinaRespondendo(accepted: true, seen: true)

        #expect(try await repo.unseenAcceptances().isEmpty)
    }

    @Test("Recusa não vira novidade")
    func declineIsNotNews() async throws {
        // Ninguém merece uma tela comemorativa para saber que foi recusado.
        let (repo, _) = try comMinhaMarinaRespondendo(accepted: false)

        #expect(try await repo.unseenAcceptances().isEmpty)
    }
}
