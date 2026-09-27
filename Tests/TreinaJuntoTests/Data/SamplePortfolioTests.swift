import Testing
@testable import TreinaJunto

@Suite("Dados · Portfólio de exemplo")
struct SamplePortfolioTests {
    @Test("O portfólio de um mesmo parceiro é estável entre execuções")
    func sampleIsDeterministic() {
        let partner = Fixtures.partner(name: "Beatriz")
        let primeiro = SampleData.portfolio(for: partner)
        let segundo = SampleData.portfolio(for: partner)

        #expect(primeiro.compatibility == segundo.compatibility)
        #expect(primeiro.streak == segundo.streak)
        #expect(primeiro.reliability == segundo.reliability)
        #expect(primeiro.days == segundo.days)
    }

    @Test("A confiabilidade fica entre 0 e 100", arguments: ["Marina", "Lucas", "Beatriz", "Rafael"])
    func reliabilityStaysInRange(name: String) {
        let portfolio = SampleData.portfolio(for: Fixtures.partner(name: name))
        #expect((0 ... 100).contains(portfolio.reliability))
    }

    @Test("A compatibilidade fica entre 0 e 100", arguments: ["Marina", "Lucas", "Beatriz", "Rafael"])
    func compatibilityStaysInRange(name: String) {
        let portfolio = SampleData.portfolio(for: Fixtures.partner(name: name))
        #expect((0 ... 100).contains(portfolio.compatibility))
    }

    @Test("Todo dia treinado em conjunto registra com quem foi")
    func trainedDaysAlwaysNameAPartner() {
        let portfolio = SampleData.portfolio(for: Fixtures.partner(name: "Rafael"))
        for (dia, estado) in portfolio.days where estado == .trainedTogether {
            #expect(portfolio.dayPartners[dia] != nil)
        }
    }
}
