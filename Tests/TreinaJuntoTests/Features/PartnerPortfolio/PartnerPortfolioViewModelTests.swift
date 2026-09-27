import Foundation
import Testing
@testable import TreinaJunto

@MainActor
@Suite("Portfólio · ViewModel")
struct PartnerPortfolioViewModelTests {
    @Test("Carregar traz o portfólio do parceiro pedido")
    func loadFetchesTheRightPortfolio() async throws {
        let repo = InMemoryPartnerRepository()
        let marina = try #require(try await repo.nearbyPartners().first { $0.name == "Marina" })
        let model = PartnerPortfolioViewModel(partner: marina, repository: repo)

        await model.load()

        #expect(model.state.value?.partner.id == marina.id)
    }

    @Test("O nome da pessoa já está disponível antes de carregar")
    func knownPartnerIsAvailableUpFront() {
        // É o que permite o topo desenhar na hora em vez de piscar em branco.
        let marina = Fixtures.partner(name: "Marina")
        let model = PartnerPortfolioViewModel(partner: marina, repository: InMemoryPartnerRepository())

        #expect(model.knownPartner.name == "Marina")
        #expect(model.state.value == nil)
    }

    @Test("Parceiro desconhecido vira mensagem de erro, não tela vazia")
    func unknownPartnerShowsAnError() async {
        let desconhecido = Fixtures.partner(name: "Fulano")
        let model = PartnerPortfolioViewModel(
            partner: desconhecido,
            repository: InMemoryPartnerRepository()
        )

        await model.load()

        #expect(model.state.errorMessage?.contains("Fulano") == true)
    }
}
