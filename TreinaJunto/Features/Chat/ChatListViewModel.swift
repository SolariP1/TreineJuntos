import Foundation

/// O estado e as ações da aba Chat: a lista, criar grupo e entrar por link.
@Observable
@MainActor
final class ChatListViewModel {
    private(set) var conversations: LoadState<[ConversationSummary]> = .idle
    /// O grupo de um link aberto, esperando a pessoa decidir se entra.
    var groupPreview: ConversationSummary?
    var toastMessage: String?

    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    /// Quem posso chamar para um grupo: as pessoas das minhas conversas
    /// privadas. Sem curtida mútua, só pelo link.
    var contacts: [WorkoutPartner] {
        (conversations.value ?? [])
            .filter { !$0.isGroup }
            .compactMap(\.others.first)
    }

    func load() async {
        if conversations.value == nil {
            conversations = .loading
        }
        do {
            conversations = try await .loaded(repository.summaries())
        } catch {
            conversations = .failed("Não deu pra carregar as conversas. Tente de novo.")
        }
    }

    /// Cria o grupo e devolve o resumo dele, para a tela abrir a conversa.
    func createGroup(named name: String, with members: Set<UUID>) async -> ConversationSummary? {
        do {
            // Ordem estável: quem aparece primeiro na lista entra primeiro.
            let ordem = contacts.map(\.id).filter(members.contains)
            let grupo = try await repository.createGroup(named: name, with: ordem)
            await load()
            return conversations.value?.first { $0.id == grupo.id }
        } catch ConversationError.groupNeedsAName {
            toast("Dê um nome ao grupo.")
        } catch {
            toast("Não deu pra criar o grupo.")
        }
        return nil
    }

    /// Um link de grupo foi aberto. Mostra o grupo antes — entrar é decisão
    /// de quem abriu, não efeito colateral de tocar num link.
    func openInviteLink(token: String) async {
        do {
            let resumo = try await repository.previewGroup(withToken: token)
            if resumo.conversation.contains(SampleData.meID) {
                toast("Você já está em \(resumo.title).")
                return
            }
            groupPreview = resumo
        } catch ConversationError.linkExpired {
            toast("Esse link de grupo venceu. Peça um novo.")
        } catch ConversationError.linkRevoked {
            toast("Esse link de grupo não vale mais.")
        } catch {
            toast("Não achamos esse grupo.")
        }
    }

    /// Entra no grupo que estava em prévia.
    func joinPreviewedGroup(token: String) async -> ConversationSummary? {
        groupPreview = nil
        do {
            let grupo = try await repository.joinGroup(withToken: token)
            await load()
            return conversations.value?.first { $0.id == grupo.id }
        } catch {
            toast("Não deu pra entrar no grupo.")
            return nil
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
