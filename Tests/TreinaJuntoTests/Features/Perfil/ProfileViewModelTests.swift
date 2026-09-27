import Foundation
import Testing
@testable import TreinaJunto

/// Repositório que aceita ler mas recusa gravar, para exercitar o desfazer.
private actor RejectingProfileRepository: ProfileRepository {
    private let stored: UserProfile

    init(stored: UserProfile = SampleData.profile) {
        self.stored = stored
    }

    func currentProfile() async throws -> UserProfile {
        stored
    }

    func save(_: UserProfile) async throws {
        throw PartnerError.notFound
    }
}

@MainActor
@Suite("Perfil · ViewModel")
struct ProfileViewModelTests {
    @Test("Carregar traz o perfil")
    func loadFetchesTheProfile() async {
        let model = ProfileViewModel(repository: InMemoryProfileRepository())

        await model.load()

        #expect(model.profile?.name == SampleData.profile.name)
    }

    @Test("Salvar mantém a edição na tela")
    func savingKeepsTheEdit() async throws {
        let model = ProfileViewModel(repository: InMemoryProfileRepository())
        await model.load()
        var editado = try #require(model.profile)
        editado.name = "Lucas Santos"

        await model.save(editado)

        #expect(model.profile?.name == "Lucas Santos")
    }

    @Test("O que foi salvo sobrevive a recarregar")
    func savedEditSurvivesAReload() async throws {
        let repo = InMemoryProfileRepository()
        let model = ProfileViewModel(repository: repo)
        await model.load()
        var editado = try #require(model.profile)
        editado.city = "São Paulo, SP"

        await model.save(editado)
        await model.load()

        #expect(model.profile?.city == "São Paulo, SP")
    }

    @Test("Se gravar falhar, a tela volta ao perfil anterior")
    func failedSaveRollsBack() async throws {
        // A edição aparece na hora, mas não pode ficar na tela mentindo que
        // foi gravada quando o servidor recusou.
        let model = ProfileViewModel(repository: RejectingProfileRepository())
        await model.load()
        let original = try #require(model.profile)
        var editado = original
        editado.name = "Nome que não vai colar"

        await model.save(editado)

        #expect(model.profile?.name == original.name)
    }
}
