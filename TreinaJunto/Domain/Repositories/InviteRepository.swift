import Foundation

/// Convites para treinar junto.
///
/// Vive ao lado do `WorkoutRepository` porque convite e treino são o mesmo
/// assunto: aceitar um convite **põe a pessoa dentro do treino**, e as duas
/// coisas precisam acontecer juntas ou nenhuma.
protocol InviteRepository: Sendable {
    /// Convites que chegaram para mim e ainda não respondi.
    func receivedInvites() async throws -> [ReceivedInvite]

    /// Convido alguém para um treino meu.
    func invite(partnerID: UUID, toWorkout workoutID: UUID) async throws

    /// O convite que recebi para um treino, respondido ou não. É o que o
    /// card na conversa usa para saber se mostra Aceitar ou "Você entrou".
    func myInvite(toWorkout workoutID: UUID) async throws -> WorkoutInvite?

    /// Aceito ou recuso. Aceitar entra no treino.
    func respond(to inviteID: UUID, accepted: Bool) async throws

    /// Aceites que eu ainda não vi — o que o card de novidade mostra ao
    /// abrir o app.
    func unseenAcceptances() async throws -> [ReceivedInvite]

    /// Marca como vistos, para não aparecerem de novo.
    func markAcceptancesSeen(_ inviteIDs: [UUID]) async throws
}
