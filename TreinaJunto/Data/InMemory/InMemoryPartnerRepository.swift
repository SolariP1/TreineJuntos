import Foundation

/// Parceiros vindos do `SampleData`, enquanto não existe servidor.
///
/// É `actor` porque guarda estado mutável e vai ser acessado de fora da
/// main actor — a mesma forma que a implementação de rede vai ter, para a
/// troca não mexer em quem chama.
actor InMemoryPartnerRepository: PartnerRepository {
    private let partners: [WorkoutPartner]

    init(partners: [WorkoutPartner] = SampleData.partners) {
        self.partners = partners
    }

    func nearbyPartners(withinMeters radius: Int) async throws -> [WorkoutPartner] {
        partners
            .filter { $0.distanceInMeters <= radius }
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
    }

    func portfolio(for partnerID: UUID) async throws -> PartnerPortfolio {
        guard let partner = partners.first(where: { $0.id == partnerID }) else {
            throw PartnerError.notFound
        }
        return SampleData.portfolio(for: partner)
    }
}

enum PartnerError: Error, Equatable {
    /// A pessoa saiu da lista entre o Feed carregar e alguém tocar no card.
    case notFound
}
