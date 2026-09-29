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

    private(set) var activeWorkout: Workout?
    private(set) var inviteBalance = GymInviteBalance(perMonth: 0)

    private let partnerRepository: PartnerRepository
    private let inviteRepository: InviteRepository
    private let workoutRepository: WorkoutRepository

    init(
        partnerRepository: PartnerRepository,
        inviteRepository: InviteRepository,
        workoutRepository: WorkoutRepository
    ) {
        self.partnerRepository = partnerRepository
        self.inviteRepository = inviteRepository
        self.workoutRepository = workoutRepository
    }

    func load() async {
        partners = .loading
        do {
            async let nearby = partnerRepository.nearbyPartners()
            async let pending = inviteRepository.pendingInvites()
            partners = try await .loaded(nearby)
            invites = try await pending
            activeWorkout = try await workoutRepository.activeWorkout()
            inviteBalance = try await workoutRepository.inviteBalance()
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

    func openWorkout(sport: Sport, size: Int, when: String, gym: String?) async {
        do {
            activeWorkout = try await workoutRepository.open(
                sport: sport,
                gym: gym,
                maxParticipants: size,
                scheduledFor: nil
            )
            toast(
                size == 2
                    ? "Treino aberto: \(sport.label) — \(when.lowercased())"
                    : "Party de \(size) aberta: \(sport.label) — \(when.lowercased())"
            )
        } catch WorkoutError.alreadyHasActiveWorkout {
            toast("Você já tem um treino aberto.")
        } catch {
            toast("Não deu pra abrir o treino.")
        }
    }

    /// Começa o treino que está aberto.
    ///
    /// `usingGymInvites` só chega verdadeiro quando o treino é numa academia
    /// e a pessoa confirmou que vai levar gente com convite dela.
    func startActiveWorkout(usingGymInvites: Bool) async {
        guard let workout = activeWorkout else { return }
        do {
            try await workoutRepository.start(
                workoutID: workout.id,
                usingGymInvites: usingGymInvites
            )
            activeWorkout = try await workoutRepository.activeWorkout()
            inviteBalance = try await workoutRepository.inviteBalance()
            toast("Treino começou. Bom treino!")
        } catch let WorkoutError.notEnoughInvites(needed, available) {
            toast("Você precisa de \(needed) convites e tem \(available).")
        } catch {
            toast("Não deu pra começar o treino.")
        }
    }

    /// Encerra o treino, dizendo quem apareceu.
    func finishActiveWorkout(present: Set<UUID>) async {
        guard let workout = activeWorkout else { return }
        do {
            try await workoutRepository.finish(workoutID: workout.id, present: present)
            activeWorkout = nil
            toast("Treino encerrado.")
        } catch {
            toast("Não deu pra encerrar o treino.")
        }
    }

    func cancelActiveWorkout() async {
        guard let workout = activeWorkout else { return }
        do {
            try await workoutRepository.cancel(workoutID: workout.id)
            activeWorkout = nil
            toast("Treino cancelado.")
        } catch {
            toast("Não deu pra cancelar o treino.")
        }
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
