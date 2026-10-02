import Foundation

/// Os treinos: abrir, entrar, começar, encerrar.
///
/// Mesma costura dos outros repositórios — hoje em memória, amanhã Supabase,
/// sem tela mudando.
protocol WorkoutRepository: Sendable {
    /// O treino que ainda está de pé para mim: aberto esperando gente, ou
    /// iniciado agora. É o que alimenta a Live Activity.
    func activeWorkout() async throws -> Workout?

    /// Um treino qualquer, pelo id. É o que o convite numa conversa usa para
    /// mostrar o estado de agora: vagas, cheio, já começou.
    func workout(withID id: UUID) async throws -> Workout?

    /// Treinos abertos perto de mim, dos quais eu ainda não faço parte.
    func nearbyOpenWorkouts(withinMeters radius: Int) async throws -> [Workout]

    /// Abre um treino e me põe dentro como anfitrião.
    func open(
        sport: Sport,
        gym: String?,
        maxParticipants: Int,
        scheduledFor: Date?
    ) async throws -> Workout

    func join(workoutID: UUID) async throws
    func leave(workoutID: UUID) async throws

    /// Começa o treino. Se for na minha academia e eu marcar que vou usar
    /// convite, cada visitante gasta um — e falha se o saldo não cobrir.
    func start(workoutID: UUID, usingGymInvites: Bool) async throws

    func finish(workoutID: UUID, present: Set<UUID>) async throws
    func cancel(workoutID: UUID) async throws

    /// Quantos convites de academia ainda tenho neste ciclo.
    func inviteBalance() async throws -> GymInviteBalance
}
