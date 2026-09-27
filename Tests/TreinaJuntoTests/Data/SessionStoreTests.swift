import Foundation
import Testing
@testable import TreinaJunto

@Suite("Dados · Sessão")
struct SessionStoreTests {
    /// Um `UserDefaults` só deste teste, para não sujar o do app nem herdar
    /// sessão de uma execução anterior.
    private func makeStore() -> (UserDefaultsSessionStore, UserDefaults) {
        let nome = "teste.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: nome) ?? .standard
        return (UserDefaultsSessionStore(defaults: defaults), defaults)
    }

    @Test("Aparelho novo não tem sessão")
    func freshDeviceHasNoSession() async {
        let (store, _) = makeStore()
        #expect(await store.currentSession() == nil)
    }

    @Test("Entrar grava a sessão", arguments: [SignInMethod.apple, .google, .email])
    func signInPersists(method: SignInMethod) async throws {
        let (store, _) = makeStore()

        let session = try await store.signIn(method: method)
        let lida = await store.currentSession()

        #expect(lida == session)
        #expect(lida?.method == method)
    }

    @Test("A sessão sobrevive a fechar o app")
    func sessionSurvivesRelaunch() async throws {
        // Um store novo sobre o mesmo UserDefaults é o que acontece quando o
        // app reabre: o objeto some, o disco fica.
        let (store, defaults) = makeStore()
        let session = try await store.signIn(method: .apple)

        let apósReabrir = UserDefaultsSessionStore(defaults: defaults)

        #expect(await apósReabrir.currentSession() == session)
    }

    @Test("Sair apaga a sessão")
    func signOutClearsIt() async throws {
        let (store, _) = makeStore()
        _ = try await store.signIn(method: .apple)

        await store.signOut()

        #expect(await store.currentSession() == nil)
    }
}
