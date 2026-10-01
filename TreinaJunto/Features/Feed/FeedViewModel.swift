import Foundation

/// O estado e as ações do Feed.
///
/// Tudo o que antes vivia em `@State` dentro do `FeedView` mora aqui, onde
/// pode ser testado sem desenhar nada. A View volta a ser só desenho.
@Observable
@MainActor
final class FeedViewModel {
    private(set) var partners: LoadState<[WorkoutPartner]> = .idle
    private(set) var invites: [ReceivedInvite] = []
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
            async let pending = inviteRepository.receivedInvites()
            partners = try await .loaded(nearby)
            invites = try await pending
            activeWorkout = try await workoutRepository.activeWorkout()
            inviteBalance = try await workoutRepository.inviteBalance()
        } catch {
            partners = .failed("Não deu pra carregar quem está perto. Tente de novo.")
        }
    }

    /// Convida alguém para o meu treino aberto.
    ///
    /// Sem treino aberto não há para onde convidar — é o que separa "mandar
    /// um oi" de "vem treinar comigo às 7h".
    func invite(_ partner: WorkoutPartner) async {
        guard let workout = activeWorkout, workout.status == .open else {
            toast("Abra um treino antes de convidar alguém.")
            return
        }
        do {
            try await inviteRepository.invite(partnerID: partner.id, toWorkout: workout.id)
            invitedIDs.insert(partner.id)
            toast("Convite enviado para \(partner.name)!")
        } catch InviteError.alreadyInvited {
            // Já convidou: o botão devia estar desabilitado, então isto é
            // corrida de toque duplo. Só realinha a tela com a verdade.
            invitedIDs.insert(partner.id)
        } catch WorkoutError.full {
            toast("Seu treino já está cheio.")
        } catch {
            toast("Não deu pra enviar o convite. Tente de novo.")
        }
    }

    /// Aceitar entra no treino de quem convidou.
    func respond(to received: ReceivedInvite, accepted: Bool) async {
        let nome = received.from.name
        do {
            try await inviteRepository.respond(to: received.id, accepted: accepted)
            invites.removeAll { $0.id == received.id }
            if accepted {
                activeWorkout = try await workoutRepository.activeWorkout()
            }
            toast(accepted ? "Combinado com \(nome)!" : "Convite de \(nome) recusado.")
        } catch WorkoutError.full {
            invites.removeAll { $0.id == received.id }
            toast("O treino de \(nome) encheu.")
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
            // A tela e o repositório discordavam: o repositório tem um treino
            // que a tela não estava mostrando. Em vez de recusar e deixar a
            // pessoa sem saída, mostra o treino que existe de verdade.
            activeWorkout = try? await workoutRepository.activeWorkout()
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

    /// Fecha o treino do jeito certo para quem está pedindo: o anfitrião
    /// cancela o treino inteiro; quem entrou por convite apenas sai.
    ///
    /// Antes, sair de um treino dos outros cancelava o treino **deles** — e
    /// as outras pessoas ficavam sem treino sem entender por quê.
    func leaveOrCancelActiveWorkout() async {
        guard let workout = activeWorkout else { return }
        let souAnfitriao = workout.hostID == SampleData.meID
        do {
            if souAnfitriao {
                try await workoutRepository.cancel(workoutID: workout.id)
                toast("Treino cancelado.")
            } else {
                try await workoutRepository.leave(workoutID: workout.id)
                toast("Você saiu do treino.")
            }
            activeWorkout = nil
        } catch {
            // Se falhou, a tela precisa voltar a contar a verdade em vez de
            // mostrar um treino que talvez não exista mais.
            activeWorkout = try? await workoutRepository.activeWorkout()
            toast(souAnfitriao ? "Não deu pra cancelar o treino." : "Não deu pra sair do treino.")
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
