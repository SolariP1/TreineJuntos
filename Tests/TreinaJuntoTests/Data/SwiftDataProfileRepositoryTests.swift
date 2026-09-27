import Foundation
import SwiftData
import Testing
@testable import TreinaJunto

@Suite("Dados · Perfil em disco")
struct SwiftDataProfileRepositoryTests {
    /// Banco em memória: mesma implementação, sem tocar no disco da máquina
    /// que roda os testes.
    private func makeRepository() throws -> SwiftDataProfileRepository {
        let container = try ProfileStore.makeContainer(inMemory: true)
        return SwiftDataProfileRepository(modelContainer: container)
    }

    @Test("Primeira abertura semeia um perfil em vez de vir vazio")
    func firstLaunchSeedsAProfile() async throws {
        let repo = try makeRepository()

        let perfil = try await repo.currentProfile()

        #expect(!perfil.name.isEmpty)
    }

    @Test("O que foi gravado é o que volta")
    func savedProfileComesBack() async throws {
        let repo = try makeRepository()
        var perfil = try await repo.currentProfile()
        perfil.name = "Lucas Santos"
        perfil.city = "São Paulo, SP"

        try await repo.save(perfil)
        let lido = try await repo.currentProfile()

        #expect(lido.name == "Lucas Santos")
        #expect(lido.city == "São Paulo, SP")
    }

    @Test("Gravar duas vezes não cria dois perfis")
    func savingTwiceKeepsOneProfile() async throws {
        let repo = try makeRepository()
        var perfil = try await repo.currentProfile()

        perfil.name = "Primeiro"
        try await repo.save(perfil)
        perfil.name = "Segundo"
        try await repo.save(perfil)

        #expect(try await repo.currentProfile().name == "Segundo")
    }

    @Test("As listas do perfil sobrevivem à ida e volta do banco")
    func nestedListsRoundTrip() async throws {
        // Rotina e avaliações são guardadas codificadas; se a volta quebrar,
        // o perfil reabre sem treino e sem avaliação, calado.
        let repo = try makeRepository()
        let original = try await repo.currentProfile()

        try await repo.save(original)
        let lido = try await repo.currentProfile()

        #expect(lido.weeklySplit.count == original.weeklySplit.count)
        #expect(lido.reviews.count == original.reviews.count)
        #expect(lido.sports == original.sports)
        #expect(lido.weeklySplit.first?.exercises == original.weeklySplit.first?.exercises)
    }

    @Test("Esporte que o app não conhece mais é ignorado, não derruba o perfil")
    func unknownSportIsDropped() async throws {
        let container = try ProfileStore.makeContainer(inMemory: true)
        let repo = SwiftDataProfileRepository(modelContainer: container)
        var perfil = try await repo.currentProfile()
        perfil.sports = [.corrida]
        try await repo.save(perfil)

        // Simula um esporte gravado por uma versão futura do app.
        let contexto = ModelContext(container)
        let guardados = try contexto.fetch(FetchDescriptor<StoredProfile>())
        guardados.first?.sportsRaw = ["corrida", "parkour"]
        try contexto.save()

        #expect(try await repo.currentProfile().sports == [.corrida])
    }
}
