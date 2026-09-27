import Foundation

/// De onde vêm os parceiros de treino.
///
/// É protocolo, e não classe, porque esta é a costura entre o app e o mundo:
/// hoje a implementação é `InMemoryPartnerRepository`, amanhã é a API. As
/// telas dependem daqui, nunca de uma implementação — e é isso que permite
/// trocar dado falso por servidor sem tocar em View nenhuma.
///
/// Os métodos são `async throws` mesmo com dados locais, de propósito: assim
/// a interface já convive com carregando e com erro desde agora, em vez de
/// ganhar esses estados num refactor de emergência no dia da integração.
protocol PartnerRepository: Sendable {
    /// Parceiros disponíveis perto de mim, do mais próximo para o mais longe.
    func nearbyPartners(withinMeters radius: Int) async throws -> [WorkoutPartner]

    /// O portfólio público de um parceiro.
    func portfolio(for partnerID: UUID) async throws -> PartnerPortfolio
}

extension PartnerRepository {
    /// Raio padrão do Feed.
    func nearbyPartners() async throws -> [WorkoutPartner] {
        try await nearbyPartners(withinMeters: 5000)
    }
}
