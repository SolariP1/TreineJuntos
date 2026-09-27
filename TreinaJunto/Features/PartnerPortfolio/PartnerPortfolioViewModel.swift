import Foundation

/// Carrega o portfólio de um parceiro.
///
/// Existe porque a tela passou a buscar o próprio dado. Antes o Feed buscava
/// antes de navegar, então tocar num card ficava sem resposta durante a
/// espera — com servidor isso seria um toque que parece ignorado.
@Observable
@MainActor
final class PartnerPortfolioViewModel {
    private(set) var state: LoadState<PartnerPortfolio> = .idle

    private let partner: WorkoutPartner
    private let repository: PartnerRepository

    init(partner: WorkoutPartner, repository: PartnerRepository) {
        self.partner = partner
        self.repository = repository
    }

    /// Enquanto o portfólio não chega, o topo já pode desenhar com o que o
    /// Feed conhece da pessoa: nome, idade, esporte e distância.
    var knownPartner: WorkoutPartner {
        partner
    }

    func load() async {
        state = .loading
        do {
            state = try await .loaded(repository.portfolio(for: partner.id))
        } catch {
            state = .failed("Não deu pra carregar o perfil de \(partner.name).")
        }
    }
}
