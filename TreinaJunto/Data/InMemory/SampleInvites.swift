import Foundation

extension SampleData {
    /// O treino da Marina tem id fixo para o chat de exemplo poder mandar o
    /// convite dele na conversa — são dois repositórios montados à parte.
    static let marinaWorkoutID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1") ?? UUID()

    /// Monta o repositório com um cenário plausível: duas pessoas perto
    /// abriram treino e me convidaram.
    ///
    /// Sem isto o Feed nasceria vazio, e a tela de convites nunca seria vista
    /// enquanto não houver servidor.
    static func seededWorkoutRepository() -> InMemoryWorkoutRepository {
        let camila = partners.first { $0.name == "Marina" }
        let thiago = partners.first { $0.name == "Beatriz" }

        var treinos: [Workout] = []
        var convites: [WorkoutInvite] = []

        if let camila, let treino = try? Workout(
            id: marinaWorkoutID,
            hostID: camila.id,
            sport: .corrida,
            maxParticipants: 2,
            scheduledFor: Date().addingTimeInterval(3600)
        ) {
            treinos.append(treino)
            convites.append(
                WorkoutInvite(workoutID: treino.id, fromProfileID: camila.id, toProfileID: meID)
            )
        }

        if let thiago, let treino = try? Workout(
            hostID: thiago.id,
            sport: .funcional,
            maxParticipants: 4,
            scheduledFor: Date().addingTimeInterval(86400)
        ) {
            treinos.append(treino)
            convites.append(
                WorkoutInvite(workoutID: treino.id, fromProfileID: thiago.id, toProfileID: meID)
            )
        }

        return InMemoryWorkoutRepository(workouts: treinos, invites: convites)
    }
}
