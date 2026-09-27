import Testing
@testable import TreinaJunto

@Suite("Domínio · UserProfile")
struct UserProfileTests {
    @Test("O perfil novo começa sem fotos")
    func startsWithoutPhotos() {
        #expect(Fixtures.profile().photos.isEmpty)
    }

    @Test("Os esportes do perfil existem no catálogo do app")
    func sportsComeFromTheCatalogue() {
        for esporte in Fixtures.profile().sports {
            #expect(availableSports.contains(esporte))
        }
    }

    @Test("Os interesses do perfil existem no catálogo do app")
    func interestsComeFromTheCatalogue() {
        for interesse in Fixtures.profile().trainingInterests {
            #expect(availableInterests.contains(interesse))
        }
    }

    @Test("Nenhum dia do treino semanal fica sem exercício")
    func weeklySplitIsNeverEmpty() {
        for dia in Fixtures.profile().weeklySplit {
            #expect(!dia.exercises.isEmpty, "\(dia.day) está sem exercícios")
        }
    }
}
