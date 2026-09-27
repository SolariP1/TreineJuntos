import SwiftData
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
    let workouts: WorkoutRepository
    let session: SessionStore

    init(
        partners: PartnerRepository = InMemoryPartnerRepository(),
        invites: InviteRepository = InMemoryInviteRepository(),
        profiles: ProfileRepository = InMemoryProfileRepository(),
        workouts: WorkoutRepository = InMemoryWorkoutRepository(),
        session: SessionStore = UserDefaultsSessionStore()
    ) {
        self.partners = partners
        self.invites = invites
        self.profiles = profiles
        self.workouts = workouts
        self.session = session
    }

    /// As dependências de verdade do app: perfil em disco, sessão no
    /// aparelho. Parceiros e convites seguem em memória até haver servidor.
    static func live() -> AppDependencies {
        do {
            let container = try ProfileStore.makeContainer()
            return AppDependencies(profiles: SwiftDataProfileRepository(modelContainer: container))
        } catch {
            // Sem banco, o app ainda abre — o perfil só não sobrevive a
            // fechar. É melhor do que não abrir.
            return AppDependencies()
        }
    }

    /// Usado pelo ambiente e pelos previews. Um só, para não realocar
    /// repositório a cada leitura do Environment.
    static let preview = AppDependencies()
}

extension EnvironmentValues {
    @Entry var dependencies = AppDependencies.preview
}
