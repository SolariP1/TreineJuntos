import Foundation

/// Perfil guardado em memória, enquanto não existe persistência.
///
/// O que é gravado aqui some ao fechar o app — mesmo comportamento de hoje.
/// A troca por SwiftData na fase 7 acontece atrás deste protocolo, sem a
/// tela perceber.
actor InMemoryProfileRepository: ProfileRepository {
    private var profile: UserProfile

    init(profile: UserProfile = SampleData.profile) {
        self.profile = profile
    }

    func currentProfile() async throws -> UserProfile {
        profile
    }

    func save(_ profile: UserProfile) async throws {
        self.profile = profile
    }
}
