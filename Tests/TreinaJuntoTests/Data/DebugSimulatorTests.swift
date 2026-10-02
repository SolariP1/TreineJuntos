#if DEBUG
    import Foundation
    import Testing
    @testable import TreinaJunto

    @Suite("Dados · Simulador de debug")
    struct DebugSimulatorTests {
        private let marina = SampleData.partners[0]
        private let beatriz = SampleData.partners[2]

        @Test("Quem eu curti me curte de volta e a conversa abre")
        func everyoneLikesBack() async throws {
            let chat = InMemoryChatRepository()
            try await chat.like(beatriz.id)
            let simulador = DebugSimulator(workouts: InMemoryWorkoutRepository(), chat: chat)

            let resultado = await simulador.everyoneLikesBack()

            #expect(resultado == "1 conversa(s) nova(s) no Chat.")
            #expect(try await chat.conversations().count == 1)
        }

        @Test("Alguém aceitar o meu convite ocupa a vaga")
        func acceptFillsSlot() async throws {
            let treinos = InMemoryWorkoutRepository()
            let treino = try await treinos.open(
                sport: .corrida,
                gym: nil,
                maxParticipants: 3,
                scheduledFor: nil
            )
            try await treinos.invite(partnerID: marina.id, toWorkout: treino.id)
            let simulador = DebugSimulator(workouts: treinos, chat: InMemoryChatRepository())

            let resultado = await simulador.someoneAcceptsMyInvite()

            #expect(resultado == "Marina aceitou e entrou no seu treino.")
            #expect(try await treinos.activeWorkout()?.freeSpots == 1)
        }

        @Test("Sem convite esperando, explica o que fazer")
        func nothingToAccept() async {
            let simulador = DebugSimulator(
                workouts: InMemoryWorkoutRepository(),
                chat: InMemoryChatRepository()
            )

            let resultado = await simulador.someoneAcceptsMyInvite()

            #expect(resultado.contains("Abra um treino"))
        }

        @Test("A conversa mais recente responde")
        func latestConversationReplies() async throws {
            let chat = SampleData.seededChatRepository()
            let simulador = DebugSimulator(workouts: InMemoryWorkoutRepository(), chat: chat)

            _ = await simulador.latestConversationReplies()

            let conversa = try #require(try await chat.summaries().first)
            #expect(conversa.lastMessage?.authorID == marina.id)
            #expect(conversa.lastMessage?.content == .text("Tô chegando, 5 min! 🏃"))
        }

        @Test("O link de grupo que chega abre a prévia, não entra direto")
        func foreignLinkPreviews() async throws {
            let chat = InMemoryChatRepository()
            let simulador = DebugSimulator(workouts: InMemoryWorkoutRepository(), chat: chat)

            let url = try #require(await simulador.foreignGroupLink())
            let token = try #require(url.pathComponents.last)
            let previa = try await chat.previewGroup(withToken: token)

            #expect(previa.title == "Pedal de domingo")
            #expect(try await chat.conversations().isEmpty)
        }

        @Test("O app de verdade monta o simulador")
        func liveDependenciesHaveSimulator() {
            #expect(AppDependencies().simulator != nil)
        }
    }
#endif
