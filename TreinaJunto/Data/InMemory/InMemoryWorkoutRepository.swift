import Foundation

/// Treinos e convites guardados em memória, enquanto não existe servidor.
///
/// Um ator só cuida dos dois porque eles são o mesmo assunto: aceitar um
/// convite entra no treino, e as duas coisas precisam acontecer juntas ou
/// nenhuma. Separar em dois atores abriria a porta para um convite aceito
/// sem ninguém dentro do treino.
///
/// As regras continuam no domínio — aqui só se guarda.
actor InMemoryWorkoutRepository: WorkoutRepository, InviteRepository {
    /// Quem sou eu neste aparelho. Com autenticação de verdade vem da sessão.
    private let meID: UUID
    private var workouts: [UUID: Workout] = [:]
    private var invites: [UUID: WorkoutInvite] = [:]
    private var partners: [UUID: WorkoutPartner] = [:]
    private var inviteUses: [Date] = []
    private let invitesPerMonth: Int

    init(
        meID: UUID = SampleData.meID,
        invitesPerMonth: Int = 4,
        workouts: [Workout] = [],
        invites: [WorkoutInvite] = [],
        partners: [WorkoutPartner] = SampleData.partners
    ) {
        self.meID = meID
        self.invitesPerMonth = invitesPerMonth
        self.workouts = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
        self.invites = Dictionary(uniqueKeysWithValues: invites.map { ($0.id, $0) })
        self.partners = Dictionary(uniqueKeysWithValues: partners.map { ($0.id, $0) })
    }

    // MARK: - Treinos

    func activeWorkout() async throws -> Workout? {
        workouts.values.first { $0.contains(meID) && ($0.status == .open || $0.status == .started) }
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
        try mutateWorkout(workoutID) { try $0.join(meID) }
    }

    func leave(workoutID: UUID) async throws {
        try mutateWorkout(workoutID) { try $0.leave(meID) }
    }

    func start(workoutID: UUID, usingGymInvites: Bool) async throws {
        let saldo = try await inviteBalance()
        var gastos = 0

        try mutateWorkout(workoutID) { workout in
            try workout.start(
                usingGymInvites: usingGymInvites,
                invitesAvailable: saldo.available()
            )
            gastos = workout.usedGymInvites
        }

        inviteUses.append(contentsOf: Array(repeating: Date(), count: gastos))
    }

    func finish(workoutID: UUID, present: Set<UUID>) async throws {
        try mutateWorkout(workoutID) { try $0.finish(present: present) }
    }

    func cancel(workoutID: UUID) async throws {
        try mutateWorkout(workoutID) { try $0.cancel() }
    }

    func inviteBalance() async throws -> GymInviteBalance {
        GymInviteBalance(perMonth: invitesPerMonth, uses: inviteUses)
    }

    // MARK: - Convites

    func receivedInvites() async throws -> [ReceivedInvite] {
        invites.values
            .filter { $0.toProfileID == meID && $0.isPending }
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap(context(for:))
    }

    func invite(partnerID: UUID, toWorkout workoutID: UUID) async throws {
        guard let workout = workouts[workoutID] else { throw WorkoutError.workoutNotFound }
        guard workout.hostID == meID else { throw InviteError.notMyWorkout }
        guard workout.status == .open else { throw InviteError.workoutNotOpen }
        guard !workout.isFull else { throw WorkoutError.full }
        guard !workout.contains(partnerID) else { throw WorkoutError.alreadyJoined }

        let jaConvidado = invites.values.contains {
            $0.workoutID == workoutID && $0.toProfileID == partnerID && $0.isPending
        }
        guard !jaConvidado else { throw InviteError.alreadyInvited }

        let convite = WorkoutInvite(
            workoutID: workoutID,
            fromProfileID: meID,
            toProfileID: partnerID
        )
        invites[convite.id] = convite
    }

    func respond(to inviteID: UUID, accepted: Bool) async throws {
        guard var convite = invites[inviteID] else { throw InviteError.inviteNotFound }

        // Entrar no treino primeiro: se o treino encheu enquanto o convite
        // estava parado, o convite não pode virar aceito no vazio.
        if accepted {
            try mutateWorkout(convite.workoutID) { try $0.join(convite.toProfileID) }
        }

        try convite.respond(accepted: accepted)
        invites[inviteID] = convite
    }

    func unseenAcceptances() async throws -> [ReceivedInvite] {
        invites.values
            .filter { $0.fromProfileID == meID && $0.status == .accepted && !$0.acceptanceSeen }
            .sorted { ($0.respondedAt ?? $0.createdAt) < ($1.respondedAt ?? $1.createdAt) }
            .compactMap(context(for:))
    }

    func markAcceptancesSeen(_ inviteIDs: [UUID]) async throws {
        for id in inviteIDs {
            invites[id]?.markAcceptanceSeen()
        }
    }

    // MARK: - Apoio

    /// Junta o convite com quem está do outro lado e com o treino. Um convite
    /// sem treino ou sem pessoa não tem como ser desenhado, então some da
    /// lista em vez de quebrar a tela.
    private func context(for invite: WorkoutInvite) -> ReceivedInvite? {
        let outroID = invite.fromProfileID == meID ? invite.toProfileID : invite.fromProfileID
        guard let partner = partners[outroID], let workout = workouts[invite.workoutID] else {
            return nil
        }
        return ReceivedInvite(invite: invite, from: partner, workout: workout)
    }

    private func mutateWorkout(_ id: UUID, _ change: (inout Workout) throws -> Void) throws {
        guard var workout = workouts[id] else { throw WorkoutError.workoutNotFound }
        try change(&workout)
        workouts[id] = workout
    }
}

extension SampleData {
    /// Identificador de quem está usando o app enquanto não há autenticação.
    static let meID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
}
