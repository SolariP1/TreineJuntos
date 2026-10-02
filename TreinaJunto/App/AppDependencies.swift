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
    /// Mesmo ator dos treinos: quem manda foto depende de quem está no treino.
    let photos: WorkoutPhotoRepository
    let chat: ChatRepository
    let session: SessionStore
    #if DEBUG
        /// Finge o outro lado enquanto não há servidor. `nil` quando algum
        /// repositório não é o de memória — aí não há o que fingir.
        let simulator: DebugSimulator?
    #endif

    init(
        partners: PartnerRepository = InMemoryPartnerRepository(),
        invites: InviteRepository? = nil,
        profiles: ProfileRepository = InMemoryProfileRepository(),
        workouts: WorkoutRepository? = nil,
        chat: ChatRepository = SampleData.seededChatRepository(),
        session: SessionStore = UserDefaultsSessionStore()
    ) {
        // Treinos e convites são o mesmo ator: aceitar um convite entra no
        // treino, e separar abriria a porta para um sem o outro.
        let treinos = SampleData.seededWorkoutRepository()
        self.partners = partners
        self.invites = invites ?? treinos
        self.profiles = profiles
        self.workouts = workouts ?? treinos
        photos = (self.workouts as? WorkoutPhotoRepository) ?? treinos
        self.chat = chat
        #if DEBUG
            let treinosEmMemoria = self.workouts as? InMemoryWorkoutRepository
            let chatEmMemoria = chat as? InMemoryChatRepository
            if let treinosEmMemoria, let chatEmMemoria {
                simulator = DebugSimulator(workouts: treinosEmMemoria, chat: chatEmMemoria)
            } else {
                simulator = nil
            }
        #endif
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
