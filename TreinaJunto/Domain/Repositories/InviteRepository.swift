import Foundation

/// Convites para treinar junto, nos dois sentidos.
protocol InviteRepository: Sendable {
    /// Convites que chegaram para mim e ainda não respondi.
    func pendingInvites() async throws -> [IncomingInvite]

    /// Convido alguém para treinar.
    ///
    /// Lança `InviteError.alreadyInvited` se já existe convite meu em aberto
    /// para essa pessoa.
    func invite(partnerID: UUID) async throws

    /// Aceito ou recuso um convite que recebi.
    func respond(to inviteID: UUID, accepted: Bool) async throws

    /// Anuncia que estou livre para treinar, para quem estiver perto.
    func publishAvailability(sport: Sport, when: String) async throws
}

enum InviteError: Error, Equatable {
    /// Já convidei essa pessoa e o convite segue em aberto.
    case alreadyInvited
    /// O convite não existe mais — a pessoa cancelou, ou já respondi.
    case inviteNotFound
}
