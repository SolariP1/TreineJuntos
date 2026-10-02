import Foundation

/// O que o card de convite de treino mostra numa conversa, para quem está
/// olhando agora.
///
/// A mesma mensagem aparece diferente para cada pessoa e muda com o tempo:
/// o anfitrião vê as vagas, quem foi chamado vê Aceitar, e quando o treino
/// enche todo mundo vê "Treino cheio" (docs/PRODUTO.md §9.3).
enum WorkoutInviteCardState: Equatable {
    /// Sou o anfitrião: acompanho as vagas.
    case host(freeSpots: Int)
    /// Fui chamado e ainda dá para entrar.
    case canRespond(inviteID: UUID)
    case joined
    case declined
    case full
    case alreadyStarted
    case closed
    /// Entrei na conversa depois do convite: ele não era para mim.
    case notForMe

    static func make(workout: Workout, myInvite: WorkoutInvite?, meID: UUID) -> WorkoutInviteCardState {
        if workout.hostID == meID {
            return .host(freeSpots: workout.freeSpots)
        }
        if workout.contains(meID) {
            return .joined
        }
        switch workout.status {
        case .open: break
        case .started: return .alreadyStarted
        case .finished, .cancelled: return .closed
        }
        if myInvite?.status == .declined {
            return .declined
        }
        if workout.isFull {
            return .full
        }
        if let convite = myInvite, convite.isPending {
            return .canRespond(inviteID: convite.id)
        }
        return .notForMe
    }

    var caption: String {
        switch self {
        case let .host(vagas):
            switch vagas {
            case 0: "Treino cheio"
            case 1: "Você convidou · falta 1 pessoa"
            default: "Você convidou · faltam \(vagas) pessoas"
            }
        case .canRespond: "Bora?"
        case .joined: "Você entrou"
        case .declined: "Você recusou"
        case .full: "Treino cheio"
        case .alreadyStarted: "O treino já começou"
        case .closed: "Este treino acabou"
        case .notForMe: "Convite de antes de você entrar"
        }
    }
}
