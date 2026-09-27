import Foundation
import Testing
@testable import TreinaJunto

@Suite("Dados · Repositório de parceiros")
struct PartnerRepositoryTests {
    @Test("A lista vem do mais perto para o mais longe")
    func nearbyComesSortedByProximity() async throws {
        let repo = InMemoryPartnerRepository()

        let encontrados = try await repo.nearbyPartners()

        let distancias = encontrados.map(\.distanceInMeters)
        #expect(distancias == distancias.sorted())
    }

    @Test("O raio corta quem está longe demais")
    func radiusExcludesDistantPartners() async throws {
        let repo = InMemoryPartnerRepository()

        let ateUmKm = try await repo.nearbyPartners(withinMeters: 1000)

        #expect(ateUmKm.count == 2)
        #expect(ateUmKm.allSatisfy { $0.distanceInMeters <= 1000 })
    }

    @Test("Raio zero não traz ninguém")
    func zeroRadiusReturnsNobody() async throws {
        let repo = InMemoryPartnerRepository()

        #expect(try await repo.nearbyPartners(withinMeters: 0).isEmpty)
    }

    @Test("O portfólio de um parceiro conhecido é o dele")
    func portfolioBelongsToTheRequestedPartner() async throws {
        let repo = InMemoryPartnerRepository()
        let marina = try #require(try await repo.nearbyPartners().first { $0.name == "Marina" })

        let portfolio = try await repo.portfolio(for: marina.id)

        #expect(portfolio.partner.id == marina.id)
    }

    @Test("Pedir o portfólio de quem não existe falha")
    func unknownPartnerHasNoPortfolio() async throws {
        let repo = InMemoryPartnerRepository()

        await #expect(throws: PartnerError.notFound) {
            _ = try await repo.portfolio(for: UUID())
        }
    }
}
