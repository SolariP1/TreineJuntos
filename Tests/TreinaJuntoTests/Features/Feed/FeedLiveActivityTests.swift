import Foundation
import Testing
@testable import TreinaJunto

/// Guarda o que o Feed pediu à Live Activity, sem ActivityKit.
@MainActor
private final class RecordingActivity: WorkoutActivityPresenting {
    private(set) var synced: [Workout?] = []
    private(set) var finished: [Workout] = []
    private(set) var initials: [String] = []

    func sync(with workout: Workout?, partnerForID: (UUID) -> WorkoutPartner?) {
        synced.append(workout)
        initials = workout?.participants.compactMap { partnerForID($0.profileID)?.initials } ?? []
    }

    func finish(_ workout: Workout, partnerForID _: (UUID) -> WorkoutPartner?) {
        finished.append(workout)
    }
}

@MainActor
@Suite("Feed · Live Activity")
struct FeedLiveActivityTests {
    private func makeModel(
        _ activity: RecordingActivity,
        workouts: InMemoryWorkoutRepository = InMemoryWorkoutRepository()
    ) -> FeedViewModel {
        FeedViewModel(
            partnerRepository: InMemoryPartnerRepository(),
            inviteRepository: workouts,
            workoutRepository: workouts,
            chatRepository: InMemoryChatRepository(),
            activity: activity
        )
    }

    @Test("Treino aberto ainda não tem Live Activity")
    func openWorkoutHasNoActivity() async {
        let atividade = RecordingActivity()
        let model = makeModel(atividade)
        await model.load()

        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        #expect(atividade.synced.allSatisfy { $0?.status != .started })
    }

    @Test("Começar sobe a Live Activity com a hora de início")
    func startingRaisesActivity() async throws {
        let atividade = RecordingActivity()
        let model = makeModel(atividade)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        await model.startActiveWorkout(usingGymInvites: false)

        let ultimo = try #require(atividade.synced.last.flatMap { $0 })
        #expect(ultimo.status == .started)
        #expect(ultimo.startedAt != nil)
    }

    @Test("A Live Activity leva quem está no treino")
    func activityCarriesParticipants() async throws {
        let marina = SampleData.partners[0]
        let treinos = InMemoryWorkoutRepository()
        let atividade = RecordingActivity()
        let model = makeModel(atividade, workouts: treinos)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        let treino = try #require(model.activeWorkout)
        try await treinos.invite(partnerID: marina.id, toWorkout: treino.id)
        _ = try await treinos.debugAcceptOldestPendingInvite()
        await model.refreshActiveWorkout()

        await model.startActiveWorkout(usingGymInvites: false)

        #expect(atividade.initials == ["M"])
    }

    @Test("Encerrar mostra o tempo final, com a hora do fim")
    func finishingShowsFinalTime() async throws {
        let atividade = RecordingActivity()
        let model = makeModel(atividade)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)
        await model.startActiveWorkout(usingGymInvites: false)

        await model.finishActiveWorkout(present: [SampleData.meID])

        let encerrado = try #require(atividade.finished.last)
        #expect(encerrado.status == .finished)
        #expect(encerrado.finishedAt != nil)
    }

    @Test("Cancelar derruba a Live Activity")
    func cancellingClearsActivity() async {
        let atividade = RecordingActivity()
        let model = makeModel(atividade)
        await model.load()
        await model.openWorkout(sport: .corrida, size: 2, when: "Agora", gym: nil)

        await model.leaveOrCancelActiveWorkout()

        #expect(atividade.synced.last == .some(nil))
    }

    @Test("Abrir o app com treino iniciado traz a Live Activity de volta")
    func reopeningRestoresActivity() async throws {
        var treino = try Workout(hostID: SampleData.meID, sport: .yoga)
        try treino.start()
        let atividade = RecordingActivity()
        let model = makeModel(atividade, workouts: InMemoryWorkoutRepository(workouts: [treino]))

        await model.load()

        #expect(atividade.synced.last??.id == treino.id)
    }
}
