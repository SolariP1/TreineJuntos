import Foundation

/// O estado e as ações de uma conversa aberta.
@Observable
@MainActor
final class ConversationViewModel {
    let summary: ConversationSummary
    private(set) var messages: [ChatMessage] = []
    private(set) var inviteLink: GroupInviteLink?
    /// O treino e o estado do card de cada convite de treino da conversa,
    /// pela chave do treino.
    private(set) var workoutCards: [UUID: WorkoutCard] = [:]
    var draft = ""
    var toastMessage: String?

    struct WorkoutCard: Equatable {
        let workout: Workout
        let state: WorkoutInviteCardState
    }

    private let repository: ChatRepository
    private let invites: InviteRepository
    private let workouts: WorkoutRepository
    private let meID: UUID

    init(
        summary: ConversationSummary,
        repository: ChatRepository,
        invites: InviteRepository,
        workouts: WorkoutRepository,
        meID: UUID = SampleData.meID
    ) {
        self.summary = summary
        self.repository = repository
        self.invites = invites
        self.workouts = workouts
        self.meID = meID
    }

    /// Só quem criou o grupo mexe no link (docs/PRODUTO.md §9.2).
    var canManageLink: Bool {
        summary.isGroup && summary.conversation.createdBy == meID
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isMine(_ message: ChatMessage) -> Bool {
        message.authorID == meID
    }

    func load() async {
        do {
            messages = try await repository.messages(in: summary.id)
            await refreshWorkoutCards()
            if canManageLink {
                inviteLink = try await repository.currentInviteLink(for: summary.id)
            }
        } catch {
            toast("Não deu pra carregar a conversa.")
        }
    }

    func send() async {
        guard canSend else { return }
        let texto = draft
        // Limpa antes de mandar, como todo chat: a pessoa já pode escrever a
        // próxima. Se falhar, o texto volta para não se perder.
        draft = ""
        do {
            let mensagem = try await repository.send(.text(texto), to: summary.id)
            messages.append(mensagem)
        } catch {
            draft = texto
            toast("Não deu pra enviar. Tente de novo.")
        }
    }

    /// Aceito ou recuso o convite de um card. Aceitar entra no treino.
    func respond(toWorkout workoutID: UUID, accepted: Bool) async {
        guard case let .canRespond(inviteID) = workoutCards[workoutID]?.state else { return }
        do {
            try await invites.respond(to: inviteID, accepted: accepted)
            if accepted {
                toast("Você entrou no treino!")
            }
        } catch WorkoutError.full {
            toast("Alguém pegou a última vaga antes.")
        } catch InviteError.workoutNotOpen, WorkoutError.notOpen {
            toast("Esse treino já começou.")
        } catch WorkoutError.alreadyHasActiveWorkout {
            toast("Você já está em outro treino.")
        } catch {
            toast("Não deu pra responder agora.")
        }
        // Em qualquer caso, o card passa a contar o estado de agora.
        await refreshWorkoutCards()
    }

    /// Relê os treinos dos convites. O estado muda por fora da conversa —
    /// alguém entra, o treino enche, começa.
    func refreshWorkoutCards() async {
        let ids = Set(messages.compactMap { mensagem -> UUID? in
            if case let .workoutInvite(workoutID) = mensagem.content {
                return workoutID
            }
            return nil
        })
        var cards: [UUID: WorkoutCard] = [:]
        for id in ids {
            guard let treino = try? await workouts.workout(withID: id) else { continue }
            let meu = try? await invites.myInvite(toWorkout: id)
            cards[id] = WorkoutCard(
                workout: treino,
                state: .make(workout: treino, myInvite: meu, meID: meID)
            )
        }
        workoutCards = cards
    }

    func createInviteLink() async {
        do {
            inviteLink = try await repository.createInviteLink(for: summary.id)
        } catch {
            toast("Não deu pra gerar o link.")
        }
    }

    func revokeInviteLink() async {
        do {
            try await repository.revokeInviteLink(for: summary.id)
            inviteLink = nil
            toast("Link desativado. Quem não entrou não entra mais por ele.")
        } catch {
            toast("Não deu pra desativar o link.")
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
