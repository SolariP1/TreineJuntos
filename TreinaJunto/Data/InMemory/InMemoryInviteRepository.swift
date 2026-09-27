import Foundation

/// Convites guardados em memória, enquanto não existe servidor.
///
/// O estado morre junto com o app — é o mesmo comportamento de antes, quando
/// ele vivia num `@State` do `FeedView`. A diferença é que agora tem um lugar
/// só, e a regra que o governa pode ser testada.
actor InMemoryInviteRepository: InviteRepository {
    private var pending: [IncomingInvite]
    private var invitedPartnerIDs: Set<UUID> = []

    init(pending: [IncomingInvite] = SampleData.invites) {
        self.pending = pending
    }

    func pendingInvites() async throws -> [IncomingInvite] {
        pending
    }

    func invite(partnerID: UUID) async throws {
        // Regra do produto: um convite em aberto por pessoa. Antes isto era
        // um `guard` dentro do FeedView, onde nenhum teste alcançava.
        guard !invitedPartnerIDs.contains(partnerID) else {
            throw InviteError.alreadyInvited
        }
        invitedPartnerIDs.insert(partnerID)
    }

    func respond(to inviteID: UUID, accepted _: Bool) async throws {
        guard pending.contains(where: { $0.id == inviteID }) else {
            throw InviteError.inviteNotFound
        }
        pending.removeAll { $0.id == inviteID }
    }

    func publishAvailability(sport _: Sport, when _: String) async throws {
        // Sem servidor não há para quem anunciar. O método existe para o
        // fluxo da tela já falar com o repositório desde agora.
    }

    /// Quem eu já convidei — o Feed usa para desabilitar o botão.
    func hasInvited(_ partnerID: UUID) -> Bool {
        invitedPartnerIDs.contains(partnerID)
    }
}
