import Foundation

/// O estado e as ações do Perfil.
@Observable
@MainActor
final class ProfileViewModel {
    private(set) var state: LoadState<UserProfile> = .idle

    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    var profile: UserProfile? {
        state.value
    }

    func load() async {
        state = .loading
        do {
            state = try await .loaded(repository.currentProfile())
        } catch {
            state = .failed("Não deu pra carregar seu perfil.")
        }
    }

    func save(_ profile: UserProfile) async {
        // Otimista: a edição já aparece na tela enquanto grava. Sem servidor
        // não há o que dar errado; com servidor, a falha devolve o anterior.
        let anterior = state.value
        state = .loaded(profile)
        do {
            try await repository.save(profile)
        } catch {
            if let anterior {
                state = .loaded(anterior)
            }
        }
    }
}
