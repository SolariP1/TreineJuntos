#if DEBUG
    import Foundation

    /// Faz o papel do "outro lado" enquanto não existe servidor.
    ///
    /// Sem isto, metade do fluxo do §9 nunca aparece na tela: ninguém curte
    /// de volta, ninguém aceita o meu convite, ninguém manda link de grupo.
    /// Só existe em build Debug — o app publicado não tem como fingir que
    /// outra pessoa fez alguma coisa.
    struct DebugSimulator: Sendable {
        let workouts: InMemoryWorkoutRepository
        let chat: InMemoryChatRepository

        /// Cada ação devolve o texto que a tela mostra como resultado.
        func everyoneLikesBack() async -> String {
            do {
                let novas = try await chat.debugEveryoneLikesBack()
                return novas == 0
                    ? "Ninguém novo para curtir de volta. Curta alguém no Feed antes."
                    : "\(novas) conversa(s) nova(s) no Chat."
            } catch {
                return "Falhou: \(error)"
            }
        }

        func someoneAcceptsMyInvite() async -> String {
            do {
                guard let id = try await workouts.debugAcceptOldestPendingInvite() else {
                    return "Nenhum convite seu esperando resposta. Abra um treino e convide pela vaga."
                }
                let nome = SampleData.partners.first { $0.id == id }?.name ?? "Alguém"
                return "\(nome) aceitou e entrou no seu treino."
            } catch WorkoutError.full {
                return "Seu treino já está cheio."
            } catch {
                return "Falhou: \(error)"
            }
        }

        func latestConversationReplies() async -> String {
            do {
                guard let conversa = try await chat.summaries().first,
                      let autor = conversa.others.first
                else {
                    return "Nenhuma conversa para responder."
                }
                try await chat.deliver(.text("Tô chegando, 5 min! 🏃"), from: autor.id, to: conversa.id)
                return "\(autor.name) respondeu em \(conversa.title)."
            } catch {
                return "Falhou: \(error)"
            }
        }

        /// Um grupo de outra pessoa, com link. A tela abre o link como se
        /// tivesse chegado por mensagem.
        func foreignGroupLink() async -> URL? {
            guard let rafael = SampleData.partners.first(where: { $0.name == "Rafael" }) else { return nil }
            return try? await chat.debugForeignGroupLink(createdBy: rafael.id, named: "Pedal de domingo").url
        }
    }
#endif
