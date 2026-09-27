import Testing
@testable import TreinaJunto

@Suite("Domínio · UserProfile")
struct UserProfileTests {
    @Test("O perfil novo começa sem fotos")
    func startsWithoutPhotos() {
        #expect(Fixtures.profile().photos.isEmpty)
    }

    @Test("Todo esporte tem nome, cor e ícone para desenhar")
    func everySportCanBeDrawn() {
        // O catálogo agora é o próprio enum, então o que vale testar é que
        // nenhum caso ficou sem apresentação ao ser adicionado.
        for esporte in Sport.allCases {
            #expect(!esporte.label.isEmpty)
            #expect(!esporte.symbol.isEmpty)
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
