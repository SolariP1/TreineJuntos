import Foundation
import Testing
@testable import TreinaJunto

@Suite("Convite pela vaga · Estado do card")
struct WorkoutInviteCardStateTests {
    private let eu = UUID()
    private let marina = UUID()
    private let beatriz = UUID()

    private func treinoDaMarina(tamanho: Int = 2) throws -> Workout {
        try Workout(hostID: marina, sport: .corrida, maxParticipants: tamanho)
    }

    private func convite(_ treino: Workout) -> WorkoutInvite {
        WorkoutInvite(workoutID: treino.id, fromProfileID: marina, toProfileID: eu)
    }

    @Test("Quem convidou vê as vagas")
    func hostSeesFreeSpots() throws {
        let treino = try Workout(hostID: eu, sport: .corrida, maxParticipants: 4)

        let estado = WorkoutInviteCardState.make(workout: treino, myInvite: nil, meID: eu)

        #expect(estado == .host(freeSpots: 3))
        #expect(estado.caption == "Você convidou · faltam 3 pessoas")
    }

    @Test("Quem foi chamado vê Aceitar enquanto há vaga")
    func inviteeCanRespond() throws {
        let treino = try treinoDaMarina()
        let meu = convite(treino)

        #expect(WorkoutInviteCardState
            .make(workout: treino, myInvite: meu, meID: eu) == .canRespond(inviteID: meu.id))
    }

    @Test("Treino que lotou mostra cheio, mesmo com convite pendente")
    func fullWorkoutShowsFull() throws {
        var treino = try treinoDaMarina()
        try treino.join(beatriz)

        #expect(WorkoutInviteCardState.make(workout: treino, myInvite: convite(treino), meID: eu) == .full)
    }

    @Test("Depois de entrar, o card diz que eu entrei")
    func joinedShowsJoined() throws {
        var treino = try treinoDaMarina()
        try treino.join(eu)

        #expect(WorkoutInviteCardState.make(workout: treino, myInvite: nil, meID: eu) == .joined)
    }

    @Test("Treino que começou não aceita mais ninguém")
    func startedWorkoutIsClosedToNewcomers() throws {
        var treino = try treinoDaMarina(tamanho: 3)
        try treino.start()

        #expect(WorkoutInviteCardState
            .make(workout: treino, myInvite: convite(treino), meID: eu) == .alreadyStarted)
    }

    @Test("Recusado fica recusado")
    func declinedStaysDeclined() throws {
        let treino = try treinoDaMarina()
        var meu = convite(treino)
        try meu.respond(accepted: false)

        #expect(WorkoutInviteCardState.make(workout: treino, myInvite: meu, meID: eu) == .declined)
    }

    @Test("Quem entrou no grupo depois do convite não vê Aceitar")
    func lateGroupMemberCannotAccept() throws {
        #expect(try WorkoutInviteCardState
            .make(workout: treinoDaMarina(), myInvite: nil, meID: eu) == .notForMe)
    }

    @Test("Legenda das vagas no singular e no plural")
    func captionGrammar() {
        #expect(WorkoutInviteCardState.host(freeSpots: 1).caption == "Você convidou · falta 1 pessoa")
        #expect(WorkoutInviteCardState.host(freeSpots: 0).caption == "Treino cheio")
    }
}

@Suite("Convite pela vaga · Envio e aceite")
struct WorkoutInviteSenderTests {
    private let marina = SampleData.partners[0]
    private let beatriz = SampleData.partners[2]

    /// Eu com conversa com Marina e Beatriz, um grupo com as duas e um treino
    /// meu aberto.
    private struct Cenario {
        let treinos: InMemoryWorkoutRepository
        let chat: InMemoryChatRepository
        let treino: Workout
        let grupo: ConversationSummary
    }

    private func cenario(tamanho: Int = 3) async throws -> Cenario {
        let chat = InMemoryChatRepository(likedMeBy: [marina.id, beatriz.id])
        try await chat.like(marina.id)
        try await chat.like(beatriz.id)
        let grupo = try await chat.createGroup(named: "Corrida", with: [marina.id, beatriz.id])
        let resumo = try #require(try await chat.summaries().first { $0.id == grupo.id })

        let treinos = InMemoryWorkoutRepository()
        let treino = try await treinos.open(
            sport: .corrida,
            gym: nil,
            maxParticipants: tamanho,
            scheduledFor: nil
        )
        return Cenario(treinos: treinos, chat: chat, treino: treino, grupo: resumo)
    }

    @Test("Convidar um grupo chama todo mundo e manda uma mensagem só")
    func groupInviteCallsEveryone() async throws {
        let cena = try await cenario()
        let sender = WorkoutInviteSender(invites: cena.treinos, chat: cena.chat)

        let chamados = try await sender.send(cena.treino, to: cena.grupo)

        #expect(chamados == 2)
        let mensagens = try await cena.chat.messages(in: cena.grupo.id)
        #expect(mensagens.map(\.content) == [.workoutInvite(workoutID: cena.treino.id)])
    }

    @Test("Quem já tem convite pendente não é chamado de novo")
    func alreadyInvitedAreSkipped() async throws {
        let cena = try await cenario()
        try await cena.treinos.invite(partnerID: marina.id, toWorkout: cena.treino.id)
        let sender = WorkoutInviteSender(invites: cena.treinos, chat: cena.chat)

        #expect(try await sender.send(cena.treino, to: cena.grupo) == 1)
    }

    @Test("Convidar quem já foi todo convidado é recusado, sem mensagem")
    func nobodyNewIsRefused() async throws {
        let cena = try await cenario()
        let sender = WorkoutInviteSender(invites: cena.treinos, chat: cena.chat)
        try await sender.send(cena.treino, to: cena.grupo)

        await #expect(throws: InviteError.alreadyInvited) {
            try await sender.send(cena.treino, to: cena.grupo)
        }
        #expect(try await cena.chat.messages(in: cena.grupo.id).count == 1)
    }

    @Test("Só o anfitrião convida para o treino")
    func onlyHostInvites() async throws {
        let cena = try await cenario()
        let alheio = try Workout(hostID: marina.id, sport: .corrida)
        let sender = WorkoutInviteSender(invites: cena.treinos, chat: cena.chat)

        await #expect(throws: InviteError.notMyWorkout) {
            try await sender.send(alheio, to: cena.grupo)
        }
    }

    @Test("Com mais convites que vagas, o primeiro a aceitar fica com a vaga")
    func firstToAcceptWins() async throws {
        // Dupla: uma vaga só, duas pessoas chamadas.
        let treino = try Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: 2)
        let paraMarina = WorkoutInvite(
            workoutID: treino.id,
            fromProfileID: SampleData.meID,
            toProfileID: marina.id
        )
        let paraBeatriz = WorkoutInvite(
            workoutID: treino.id,
            fromProfileID: SampleData.meID,
            toProfileID: beatriz.id
        )
        let treinos = InMemoryWorkoutRepository(workouts: [treino], invites: [paraMarina, paraBeatriz])

        try await treinos.respond(to: paraMarina.id, accepted: true)

        await #expect(throws: WorkoutError.full) {
            try await treinos.respond(to: paraBeatriz.id, accepted: true)
        }
        let atual = try #require(try await treinos.workout(withID: treino.id))
        #expect(atual.contains(marina.id))
        #expect(!atual.contains(beatriz.id))
    }
}

@Suite("Convite pela vaga · Um treino por vez")
struct OneActiveWorkoutTests {
    @Test("Aceitar estando em outro treino é recusado")
    func cannotAcceptWhileInAnotherWorkout() async throws {
        let marina = SampleData.partners[0]
        let dela = try Workout(hostID: marina.id, sport: .corrida)
        let convite = WorkoutInvite(
            workoutID: dela.id,
            fromProfileID: marina.id,
            toProfileID: SampleData.meID
        )
        let meu = try Workout(hostID: SampleData.meID, sport: .yoga)
        let repo = InMemoryWorkoutRepository(workouts: [dela, meu], invites: [convite])

        await #expect(throws: WorkoutError.alreadyHasActiveWorkout) {
            try await repo.respond(to: convite.id, accepted: true)
        }
        // O convite continua de pé: dá para aceitar depois de sair do outro.
        #expect(try await repo.myInvite(toWorkout: dela.id)?.isPending == true)
    }

    @Test("Recusar estando em outro treino continua valendo")
    func canDeclineWhileInAnotherWorkout() async throws {
        let marina = SampleData.partners[0]
        let dela = try Workout(hostID: marina.id, sport: .corrida)
        let convite = WorkoutInvite(
            workoutID: dela.id,
            fromProfileID: marina.id,
            toProfileID: SampleData.meID
        )
        let meu = try Workout(hostID: SampleData.meID, sport: .yoga)
        let repo = InMemoryWorkoutRepository(workouts: [dela, meu], invites: [convite])

        try await repo.respond(to: convite.id, accepted: false)

        #expect(try await repo.myInvite(toWorkout: dela.id)?.status == .declined)
    }
}

@MainActor
@Suite("Convite pela vaga · Na conversa")
struct ConversationWorkoutInviteTests {
    @Test("Aceitar pelo card da conversa põe você no treino da Marina")
    func acceptFromConversation() async throws {
        let chat = SampleData.seededChatRepository()
        let treinos = SampleData.seededWorkoutRepository()
        let resumo = try #require(try await chat.summaries().first)
        let model = ConversationViewModel(
            summary: resumo,
            repository: chat,
            invites: treinos,
            workouts: treinos
        )
        await model.load()
        let id = SampleData.marinaWorkoutID
        guard case .canRespond = model.workoutCards[id]?.state else {
            Issue.record("O card devia oferecer Aceitar")
            return
        }

        await model.respond(toWorkout: id, accepted: true)

        #expect(model.workoutCards[id]?.state == .joined)
        #expect(try await treinos.activeWorkout()?.id == id)
    }

    @Test("Recusar pelo card não põe em treino nenhum")
    func declineFromConversation() async throws {
        let chat = SampleData.seededChatRepository()
        let treinos = SampleData.seededWorkoutRepository()
        let resumo = try #require(try await chat.summaries().first)
        let model = ConversationViewModel(
            summary: resumo,
            repository: chat,
            invites: treinos,
            workouts: treinos
        )
        await model.load()

        await model.respond(toWorkout: SampleData.marinaWorkoutID, accepted: false)

        #expect(model.workoutCards[SampleData.marinaWorkoutID]?.state == .declined)
        #expect(try await treinos.activeWorkout() == nil)
    }
}
