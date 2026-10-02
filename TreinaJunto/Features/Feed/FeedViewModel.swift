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
    /// Quem eu já curti nesta sessão, para o botão ficar marcado.
    private(set) var likedIDs: Set<UUID> = []
    /// As conversas para onde posso mandar o convite do meu treino.
    private(set) var inviteTargets: [ConversationSummary] = []

    var toastMessage: String?

    private(set) var activeWorkout: Workout?
    private(set) var inviteBalance = GymInviteBalance(perMonth: 0)

    private let partnerRepository: PartnerRepository
    private let inviteRepository: InviteRepository
    private let workoutRepository: WorkoutRepository
    private let chatRepository: ChatRepository
    private let activity: WorkoutActivityPresenting

    init(
        partnerRepository: PartnerRepository,
        inviteRepository: InviteRepository,
        workoutRepository: WorkoutRepository,
        chatRepository: ChatRepository,
        activity: WorkoutActivityPresenting
    ) {
        self.partnerRepository = partnerRepository
        self.inviteRepository = inviteRepository
        self.workoutRepository = workoutRepository
        self.chatRepository = chatRepository
        self.activity = activity
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
            // Ao abrir o app: uma atividade perdida volta, uma sobrando some.
            syncActivity()
        } catch {
            partners = .failed("Não deu pra carregar quem está perto. Tente de novo.")
        }
    }

    /// Curto alguém. Se a pessoa já tinha me curtido, a conversa abre na
    /// hora; senão fica a curtida, e ninguém fica sabendo até ser mútua
    /// (docs/PRODUTO.md §9.1).
    func like(_ partner: WorkoutPartner) async {
        guard !likedIDs.contains(partner.id) else { return }
        do {
            let conversa = try await chatRepository.like(partner.id)
            likedIDs.insert(partner.id)
            toast(
                conversa == nil
                    ? "Você curtiu \(partner.name)."
                    : "Vocês se curtiram! A conversa com \(partner.name) está no Chat."
            )
        } catch {
            toast("Não deu pra curtir agora. Tente de novo.")
        }
    }

    func hasLiked(_ partner: WorkoutPartner) -> Bool {
        likedIDs.contains(partner.id)
    }

    // MARK: - Convidar pela vaga

    /// Carrega as conversas para a folha de convidar, que abre ao tocar
    /// numa vaga livre do treino.
    func loadInviteTargets() async {
        inviteTargets = await (try? chatRepository.summaries()) ?? []
    }

    /// Manda o convite do meu treino para uma conversa. Num grupo, todo
    /// mundo é chamado e quem aceitar primeiro fica com a vaga.
    func inviteToActiveWorkout(_ summary: ConversationSummary) async {
        guard let workout = activeWorkout else { return }
        do {
            let sender = WorkoutInviteSender(invites: inviteRepository, chat: chatRepository)
            try await sender.send(workout, to: summary)
            toast("Convite enviado para \(summary.title)!")
        } catch InviteError.alreadyInvited {
            toast("\(summary.title) já tem convite para este treino.")
        } catch WorkoutError.full {
            toast("Seu treino já está cheio.")
        } catch {
            toast("Não deu pra enviar o convite. Tente de novo.")
        }
    }

    /// Recarrega o treino, para a tela mostrar quem entrou pela conversa.
    func refreshActiveWorkout() async {
        activeWorkout = try? await workoutRepository.activeWorkout()
        syncActivity()
    }

    private func syncActivity() {
        activity.sync(with: activeWorkout, partnerForID: partner(withID:))
    }

    /// O rosto de quem está no treino, quando a pessoa é conhecida.
    func partner(withID id: UUID) -> WorkoutPartner? {
        partners.value?.first { $0.id == id }
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
            syncActivity()
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
            // O tempo final fica um pouco na Dynamic Island antes de sumir.
            if let encerrado = try await workoutRepository.workout(withID: workout.id) {
                activity.finish(encerrado, partnerForID: partner(withID:))
            }
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
            syncActivity()
        } catch {
            // Se falhou, a tela precisa voltar a contar a verdade em vez de
            // mostrar um treino que talvez não exista mais.
            activeWorkout = try? await workoutRepository.activeWorkout()
            toast(souAnfitriao ? "Não deu pra cancelar o treino." : "Não deu pra sair do treino.")
        }
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
