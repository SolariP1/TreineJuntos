import Foundation
import Testing
@testable import TreinaJunto

@Suite("Dados · Repositório de treinos")
struct WorkoutRepositoryTests {
    @Test("Sem abrir nada, não há treino de pé")
    func noActiveWorkoutAtFirst() async throws {
        let repo = InMemoryWorkoutRepository()
        #expect(try await repo.activeWorkout() == nil)
    }

    @Test("Abrir põe o treino de pé, comigo dentro")
    func openingCreatesAnActiveWorkout() async throws {
        let repo = InMemoryWorkoutRepository()

        let treino = try await repo.open(sport: .corrida, gym: nil, maxParticipants: 3, scheduledFor: nil)

        #expect(treino.status == .open)
        #expect(treino.contains(SampleData.meID))
        #expect(try await repo.activeWorkout()?.id == treino.id)
    }

    @Test("Um treino de pé por vez")
    func onlyOneActiveWorkout() async throws {
        let repo = InMemoryWorkoutRepository()
        _ = try await repo.open(sport: .corrida, gym: nil, maxParticipants: 2, scheduledFor: nil)

        await #expect(throws: WorkoutError.alreadyHasActiveWorkout) {
            _ = try await repo.open(sport: .yoga, gym: nil, maxParticipants: 2, scheduledFor: nil)
        }
    }

    @Test("Cancelar libera para abrir outro")
    func cancellingFreesTheSlot() async throws {
        let repo = InMemoryWorkoutRepository()
        let primeiro = try await repo.open(sport: .corrida, gym: nil, maxParticipants: 2, scheduledFor: nil)

        try await repo.cancel(workoutID: primeiro.id)
        let segundo = try await repo.open(sport: .yoga, gym: nil, maxParticipants: 2, scheduledFor: nil)

        #expect(segundo.sport == .yoga)
    }

    @Test("Começar sem convite não mexe no saldo")
    func startingWithoutInvitesKeepsBalance() async throws {
        let repo = InMemoryWorkoutRepository(invitesPerMonth: 4)
        let treino = try await repo.open(
            sport: .corrida,
            gym: "Smart Fit",
            maxParticipants: 3,
            scheduledFor: nil
        )

        try await repo.start(workoutID: treino.id, usingGymInvites: false)

        #expect(try await repo.inviteBalance().available() == 4)
    }

    @Test("Começar com convite desconta um por visitante")
    func startingWithInvitesSpendsPerGuest() async throws {
        var treino = try Workout(
            hostID: SampleData.meID, sport: .corrida, gym: "Smart Fit", maxParticipants: 4
        )
        try treino.join(UUID())
        try treino.join(UUID())
        let repo = InMemoryWorkoutRepository(invitesPerMonth: 4, workouts: [treino])

        try await repo.start(workoutID: treino.id, usingGymInvites: true)

        // Três no treino, dois visitantes: sobram dois convites de quatro.
        #expect(try await repo.inviteBalance().available() == 2)
    }

    @Test("Saldo esgotado impede começar usando convite")
    func emptyBalanceBlocksStartingWithInvites() async throws {
        var treino = try Workout(
            hostID: SampleData.meID, sport: .corrida, gym: "Smart Fit", maxParticipants: 2
        )
        try treino.join(UUID())
        let repo = InMemoryWorkoutRepository(invitesPerMonth: 0, workouts: [treino])

        await #expect(throws: WorkoutError.notEnoughInvites(needed: 1, available: 0)) {
            try await repo.start(workoutID: treino.id, usingGymInvites: true)
        }
        // E o treino continua aberto, para a pessoa poder ajustar.
        #expect(try await repo.activeWorkout()?.status == .open)
    }

    @Test("Treino que não existe falha em vez de sumir em silêncio")
    func unknownWorkoutFails() async {
        let repo = InMemoryWorkoutRepository()

        await #expect(throws: WorkoutError.workoutNotFound) {
            try await repo.cancel(workoutID: UUID())
        }
    }
}
