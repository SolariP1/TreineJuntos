import Foundation

/// Convida uma conversa inteira para o meu treino (docs/PRODUTO.md §9.3).
///
/// O convite tem duas metades: o registro de quem foi chamado, que vive com
/// o treino, e a mensagem que aparece na conversa. Chamar alguém é criar um
/// `WorkoutInvite` para cada pessoa da conversa e mandar **uma** mensagem;
/// aceitar continua passando pelo `InviteRepository`, onde entrar no treino
/// e virar aceito acontecem juntos.
///
/// Em memória as duas metades vivem em atores diferentes e não há transação
/// entre elas. Com servidor, isto vira uma função no banco que faz as duas
/// coisas de uma vez.
struct WorkoutInviteSender: Sendable {
    let invites: InviteRepository
    let chat: ChatRepository
    var meID: UUID = SampleData.meID

    /// Manda o convite e devolve quantas pessoas foram chamadas agora.
    @discardableResult
    func send(_ workout: Workout, to summary: ConversationSummary) async throws -> Int {
        guard workout.hostID == meID else { throw InviteError.notMyWorkout }
        guard workout.status == .open else { throw InviteError.workoutNotOpen }
        guard !workout.isFull else { throw WorkoutError.full }

        // Quem já está no treino não é chamado de novo; quem já tem convite
        // pendente também não — num grupo, é comum metade já ter sido
        // chamada por outra conversa.
        var chamados = 0
        for pessoa in summary.others where !workout.contains(pessoa.id) {
            do {
                try await invites.invite(partnerID: pessoa.id, toWorkout: workout.id)
                chamados += 1
            } catch InviteError.alreadyInvited {
                continue
            }
        }
        guard chamados > 0 else { throw InviteError.alreadyInvited }

        try await chat.send(.workoutInvite(workoutID: workout.id), to: summary.id)
        return chamados
    }
}
