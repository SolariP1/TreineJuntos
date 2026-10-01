import Foundation

enum InviteStatus: String, Codable, Hashable, Sendable {
    case pending
    case accepted
    case declined
}

/// Um convite para entrar num treino.
///
/// Não é um recado solto: todo convite aponta para um treino que existe. É o
/// que transforma "manda um oi" em "vem treinar comigo às 7h".
struct WorkoutInvite: Identifiable, Hashable, Sendable {
    let id: UUID
    let workoutID: UUID
    let fromProfileID: UUID
    let toProfileID: UUID
    let createdAt: Date

    private(set) var status: InviteStatus
    private(set) var respondedAt: Date?
    /// Se quem convidou já viu que foi aceito. Alimenta o card de novidade
    /// ao abrir o app — sem isso, a mesma boa notícia apareceria toda vez.
    private(set) var acceptanceSeen: Bool

    init(
        id: UUID = UUID(),
        workoutID: UUID,
        fromProfileID: UUID,
        toProfileID: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.fromProfileID = fromProfileID
        self.toProfileID = toProfileID
        self.createdAt = createdAt
        status = .pending
        respondedAt = nil
        acceptanceSeen = false
    }

    /// Reconstrói um convite já respondido.
    ///
    /// É como ele volta do banco: o estado vem gravado, não é remontado
    /// chamando `respond` de novo.
    init(
        id: UUID = UUID(),
        workoutID: UUID,
        fromProfileID: UUID,
        toProfileID: UUID,
        createdAt: Date = Date(),
        status: InviteStatus,
        respondedAt: Date?,
        acceptanceSeen: Bool = false
    ) {
        self.id = id
        self.workoutID = workoutID
        self.fromProfileID = fromProfileID
        self.toProfileID = toProfileID
        self.createdAt = createdAt
        self.status = status
        self.respondedAt = respondedAt
        self.acceptanceSeen = acceptanceSeen
    }

    var isPending: Bool {
        status == .pending
    }

    mutating func respond(accepted: Bool, now: Date = Date()) throws {
        guard status == .pending else { throw InviteError.alreadyAnswered }
        status = accepted ? .accepted : .declined
        respondedAt = now
    }

    /// Quem convidou já viu a boa notícia.
    mutating func markAcceptanceSeen() {
        acceptanceSeen = true
    }
}

/// Um convite com o que a tela precisa para desenhar: quem chamou e para
/// qual treino.
struct ReceivedInvite: Identifiable, Hashable, Sendable {
    let invite: WorkoutInvite
    let from: WorkoutPartner
    let workout: Workout

    var id: UUID {
        invite.id
    }
}

enum InviteError: Error, Equatable {
    /// Já convidei essa pessoa para este treino e o convite segue em aberto.
    case alreadyInvited
    case inviteNotFound
    /// Aceitar ou recusar duas vezes.
    case alreadyAnswered
    /// Convidar para um treino que não é meu.
    case notMyWorkout
    /// Convidar para um treino que já começou ou acabou.
    case workoutNotOpen
}
