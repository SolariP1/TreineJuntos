import Foundation

/// O estado e as ações de uma conversa aberta.
@Observable
@MainActor
final class ConversationViewModel {
    let summary: ConversationSummary
    private(set) var messages: [ChatMessage] = []
    private(set) var inviteLink: GroupInviteLink?
    var draft = ""
    var toastMessage: String?

    private let repository: ChatRepository
    private let meID: UUID

    init(summary: ConversationSummary, repository: ChatRepository, meID: UUID = SampleData.meID) {
        self.summary = summary
        self.repository = repository
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
