import Foundation

/// O estado e as ações do Feed.
///
/// Tudo o que antes vivia em `@State` dentro do `FeedView` mora aqui, onde
/// pode ser testado sem desenhar nada. A View volta a ser só desenho.
@Observable
@MainActor
final class FeedViewModel {
    private(set) var partners: LoadState<[WorkoutPartner]> = .idle
    private(set) var invites: [IncomingInvite] = []
    private(set) var invitedIDs: Set<UUID> = []

    var toastMessage: String?

    private let partnerRepository: PartnerRepository
    private let inviteRepository: InviteRepository

    init(partnerRepository: PartnerRepository, inviteRepository: InviteRepository) {
        self.partnerRepository = partnerRepository
        self.inviteRepository = inviteRepository
    }

    func load() async {
        partners = .loading
        do {
            async let nearby = partnerRepository.nearbyPartners()
            async let pending = inviteRepository.pendingInvites()
            partners = try await .loaded(nearby)
            invites = try await pending
        } catch {
            partners = .failed("Não deu pra carregar quem está perto. Tente de novo.")
        }
    }

    func invite(_ partner: WorkoutPartner) async {
        do {
            try await inviteRepository.invite(partnerID: partner.id)
            invitedIDs.insert(partner.id)
            toast("Convite enviado para \(partner.name)!")
        } catch InviteError.alreadyInvited {
            // Já convidou: o botão devia estar desabilitado, então isto é
            // corrida de toque duplo. Só realinha a tela com a verdade.
            invitedIDs.insert(partner.id)
        } catch {
            toast("Não deu pra enviar o convite. Tente de novo.")
        }
    }

    func respond(to invite: IncomingInvite, accepted: Bool) async {
        do {
            try await inviteRepository.respond(to: invite.id, accepted: accepted)
            invites.removeAll { $0.id == invite.id }
            toast(accepted ? "Combinado com \(invite.name)!" : "Convite de \(invite.name) recusado.")
        } catch {
            toast("Não deu pra responder agora. Tente de novo.")
        }
    }

    func publishAvailability(sport: Sport, when: String) async {
        do {
            try await inviteRepository.publishAvailability(sport: sport, when: when)
            toast("Disponibilidade publicada: \(sport.label) — \(when.lowercased())")
        } catch {
            toast("Não deu pra publicar sua disponibilidade.")
        }
    }

    func portfolio(for partner: WorkoutPartner) async -> PartnerPortfolio? {
        try? await partnerRepository.portfolio(for: partner.id)
    }

    func hasInvited(_ partner: WorkoutPartner) -> Bool {
        invitedIDs.contains(partner.id)
    }

    private func toast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}
