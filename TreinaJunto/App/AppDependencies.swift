import SwiftUI

/// Onde as implementações concretas são escolhidas.
///
/// Este é o único lugar do app que sabe que os dados são falsos. Ligar um
/// servidor é trocar as três linhas do `init` por `RemotePartnerRepository`
/// e companhia — nenhuma tela muda.
///
/// É imutável e guarda só repositórios (que são `actor`), então é `Sendable`
/// e não precisa de `@Observable`: o que muda com o tempo é o estado dentro
/// de cada repositório, não a escolha de qual usar.
struct AppDependencies: Sendable {
    let partners: PartnerRepository
    let invites: InviteRepository
    let profiles: ProfileRepository

    init(
        partners: PartnerRepository = InMemoryPartnerRepository(),
        invites: InviteRepository = InMemoryInviteRepository(),
        profiles: ProfileRepository = InMemoryProfileRepository()
    ) {
        self.partners = partners
        self.invites = invites
        self.profiles = profiles
    }

    /// Usado pelo ambiente e pelos previews. Um só, para não realocar
    /// repositório a cada leitura do Environment.
    static let preview = AppDependencies()
}

extension EnvironmentValues {
    @Entry var dependencies = AppDependencies.preview
}
