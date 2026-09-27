import Foundation
import Testing
@testable import TreinaJunto

@Suite("Domínio · Treino")
struct WorkoutTests {
    private let anfitriao = UUID()
    private let marina = UUID()
    private let beatriz = UUID()

    private func abrir(tamanho: Int = 2, academia: String? = nil) throws -> Workout {
        try Workout(hostID: anfitriao, sport: .corrida, gym: academia, maxParticipants: tamanho)
    }

    // MARK: - Abertura

    @Test("Um treino nasce aberto, com o anfitrião dentro")
    func newWorkoutStartsOpenWithHost() throws {
        let treino = try abrir()

        #expect(treino.status == .open)
        #expect(treino.participants.count == 1)
        #expect(treino.contains(anfitriao))
        #expect(treino.participants.first?.isHost == true)
    }

    @Test("Tamanho válido é de 2 a 6", arguments: [2, 3, 4, 5, 6])
    func acceptsValidSizes(tamanho: Int) throws {
        #expect(try abrir(tamanho: tamanho).maxParticipants == tamanho)
    }

    @Test("Tamanho fora da faixa é recusado", arguments: [0, 1, 7, 30])
    func rejectsInvalidSizes(tamanho: Int) {
        #expect(throws: WorkoutError.invalidSize(tamanho)) {
            try abrir(tamanho: tamanho)
        }
    }

    @Test("Dois é dupla; acima disso é party")
    func partyStartsAtThree() throws {
        #expect(try abrir(tamanho: 2).isParty == false)
        #expect(try abrir(tamanho: 3).isParty == true)
    }

    // MARK: - Entrar e sair

    @Test("Entrar ocupa uma vaga")
    func joiningTakesASpot() throws {
        var treino = try abrir(tamanho: 3)

        try treino.join(marina)

        #expect(treino.contains(marina))
        #expect(treino.freeSpots == 1)
        #expect(treino.guestCount == 1)
    }

    @Test("Ninguém entra duas vezes")
    func cannotJoinTwice() throws {
        var treino = try abrir(tamanho: 3)
        try treino.join(marina)

        #expect(throws: WorkoutError.alreadyJoined) {
            try treino.join(marina)
        }
    }

    @Test("Treino cheio não aceita mais ninguém")
    func fullWorkoutRejectsNewcomers() throws {
        var treino = try abrir(tamanho: 2)
        try treino.join(marina)

        #expect(treino.isFull)
        #expect(throws: WorkoutError.full) {
            try treino.join(beatriz)
        }
    }

    @Test("Depois de começar, a lista está fechada")
    func cannotJoinAfterStart() throws {
        var treino = try abrir(tamanho: 3)
        try treino.start()

        #expect(throws: WorkoutError.notOpen) {
            try treino.join(marina)
        }
    }

    @Test("Quem desistiu libera a vaga")
    func leavingFreesTheSpot() throws {
        var treino = try abrir(tamanho: 2)
        try treino.join(marina)

        try treino.leave(marina)

        #expect(!treino.contains(marina))
        #expect(treino.freeSpots == 1)
    }

    @Test("O anfitrião não sai do próprio treino — ele cancela")
    func hostCannotLeave() throws {
        var treino = try abrir()

        #expect(throws: WorkoutError.hostCannotLeave) {
            try treino.leave(anfitriao)
        }
    }

    // MARK: - Começar

    @Test("Começar move de aberto para iniciado e marca a hora")
    func startingMovesToStarted() throws {
        var treino = try abrir()
        let agora = Date()

        try treino.start(now: agora)

        #expect(treino.status == .started)
        #expect(treino.startedAt == agora)
    }

    @Test("Não dá para começar duas vezes")
    func cannotStartTwice() throws {
        var treino = try abrir()
        try treino.start()

        #expect(throws: WorkoutError.alreadyStarted) {
            try treino.start()
        }
    }

    // MARK: - Convites de academia

    @Test("Sem usar convite, nenhum é gasto")
    func notUsingInvitesSpendsNone() throws {
        var treino = try abrir(tamanho: 3, academia: "Smart Fit")
        try treino.join(marina)

        try treino.start()

        #expect(treino.usedGymInvites == 0)
    }

    @Test("Cada visitante gasta um convite; o anfitrião não gasta o próprio")
    func eachGuestSpendsOneInvite() throws {
        var treino = try abrir(tamanho: 4, academia: "Smart Fit")
        try treino.join(marina)
        try treino.join(beatriz)

        try treino.start(usingGymInvites: true, invitesAvailable: 3)

        // Três pessoas no treino, mas só duas são visitantes.
        #expect(treino.usedGymInvites == 2)
    }

    @Test("Party maior que o saldo não começa — e diz quanto falta")
    func partyLargerThanBalanceFailsToStart() throws {
        // É o caso que o documento manda avisar na hora de abrir, e não
        // deixar a pessoa descobrir no portão da academia.
        var treino = try abrir(tamanho: 6, academia: "Smart Fit")
        try treino.join(marina)
        try treino.join(beatriz)

        #expect(throws: WorkoutError.notEnoughInvites(needed: 2, available: 1)) {
            try treino.start(usingGymInvites: true, invitesAvailable: 1)
        }
        #expect(treino.status == .open, "o treino tem que continuar aberto para a pessoa ajustar")
    }

    @Test("Treino sozinho não gasta convite nenhum")
    func soloWorkoutSpendsNoInvite() throws {
        var treino = try abrir(academia: "Smart Fit")

        try treino.start(usingGymInvites: true, invitesAvailable: 0)

        #expect(treino.usedGymInvites == 0)
    }

    // MARK: - Encerrar

    @Test("Encerrar registra quem apareceu")
    func finishingRecordsWhoShowedUp() throws {
        var treino = try abrir(tamanho: 3)
        try treino.join(marina)
        try treino.join(beatriz)
        try treino.start()

        try treino.finish(present: [anfitriao, marina])

        #expect(treino.status == .finished)
        #expect(treino.participants.first { $0.profileID == marina }?.present == true)
        #expect(treino.participants.first { $0.profileID == beatriz }?.present == false)
    }

    @Test("Quem não for citado no fim conta como ausente")
    func unnamedParticipantsCountAsAbsent() throws {
        // Silêncio no fim do treino é resposta: sem isso a confiabilidade
        // nunca sairia do lugar.
        var treino = try abrir(tamanho: 2)
        try treino.join(marina)
        try treino.start()

        try treino.finish(present: [])

        #expect(treino.participants.allSatisfy { $0.present == false })
    }

    @Test("Antes de encerrar, presença é desconhecida — não é falta")
    func presenceIsUnknownBeforeFinishing() throws {
        var treino = try abrir(tamanho: 2)
        try treino.join(marina)
        try treino.start()

        #expect(treino.participants.allSatisfy { $0.present == nil })
    }

    @Test("Treino que não começou não pode ser encerrado")
    func cannotFinishWhatNeverStarted() throws {
        var treino = try abrir()

        #expect(throws: WorkoutError.notStarted) {
            try treino.finish(present: [])
        }
    }

    // MARK: - Cancelar

    @Test("Dá para cancelar antes de começar")
    func canCancelBeforeStart() throws {
        var treino = try abrir()

        try treino.cancel()

        #expect(treino.status == .cancelled)
    }

    @Test("Depois de começar não se cancela, se encerra")
    func cannotCancelAfterStart() throws {
        var treino = try abrir()
        try treino.start()

        #expect(throws: WorkoutError.cannotCancelAfterStart) {
            try treino.cancel()
        }
    }
}
