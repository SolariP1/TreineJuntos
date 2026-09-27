import Foundation

/// Treinos guardados em memória, enquanto não existe servidor.
///
/// Segura as regras do `Workout` de verdade — abrir, entrar, começar e
/// encerrar passam pelas mesmas validações que a versão com Supabase vai
/// usar, porque as regras moram no domínio, não aqui.
actor InMemoryWorkoutRepository: WorkoutRepository {
    /// Quem sou eu neste aparelho. Com autenticação de verdade vem da sessão.
    private let meID: UUID
    private var workouts: [UUID: Workout] = [:]
    private var inviteUses: [Date] = []
    private let invitesPerMonth: Int

    init(
        meID: UUID = SampleData.meID,
        invitesPerMonth: Int = 4,
        workouts: [Workout] = []
    ) {
        self.meID = meID
        self.invitesPerMonth = invitesPerMonth
        self.workouts = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
    }

    func activeWorkout() async throws -> Workout? {
        workouts.values.first { $0.hostID == meID || $0.contains(meID) }
            .flatMap { $0.status == .open || $0.status == .started ? $0 : nil }
    }

    func nearbyOpenWorkouts(withinMeters _: Int) async throws -> [Workout] {
        workouts.values
            .filter { $0.status == .open && !$0.contains(meID) }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    func open(
        sport: Sport,
        gym: String?,
        maxParticipants: Int,
        scheduledFor: Date?
    ) async throws -> Workout {
        // Um treino de pé por vez: abrir outro deixaria a Live Activity sem
        // saber qual mostrar, e a pessoa em dois lugares ao mesmo tempo.
        if try await activeWorkout() != nil {
            throw WorkoutError.alreadyHasActiveWorkout
        }

        let workout = try Workout(
            hostID: meID,
            sport: sport,
            gym: gym,
            maxParticipants: maxParticipants,
            scheduledFor: scheduledFor
        )
        workouts[workout.id] = workout
        return workout
    }

    func join(workoutID: UUID) async throws {
        try mutate(workoutID) { try $0.join(meID) }
    }

    func leave(workoutID: UUID) async throws {
        try mutate(workoutID) { try $0.leave(meID) }
    }

    func start(workoutID: UUID, usingGymInvites: Bool) async throws {
        let saldo = try await inviteBalance()
        var gastos = 0

        try mutate(workoutID) { workout in
            try workout.start(
                usingGymInvites: usingGymInvites,
                invitesAvailable: saldo.available()
            )
            gastos = workout.usedGymInvites
        }

        inviteUses.append(contentsOf: Array(repeating: Date(), count: gastos))
    }

    func finish(workoutID: UUID, present: Set<UUID>) async throws {
        try mutate(workoutID) { try $0.finish(present: present) }
    }

    func cancel(workoutID: UUID) async throws {
        try mutate(workoutID) { try $0.cancel() }
    }

    func inviteBalance() async throws -> GymInviteBalance {
        GymInviteBalance(perMonth: invitesPerMonth, uses: inviteUses)
    }

    private func mutate(_ id: UUID, _ change: (inout Workout) throws -> Void) throws {
        guard var workout = workouts[id] else { throw WorkoutError.workoutNotFound }
        try change(&workout)
        workouts[id] = workout
    }
}

extension SampleData {
    /// Identificador de quem está usando o app enquanto não há autenticação.
    static let meID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
}
