import Foundation

/// Quem cuida da Live Activity do treino.
///
/// Protocolo para o Feed poder ser testado sem ActivityKit — no simulador de
/// testes não há Dynamic Island, e o que importa verificar é **quando** a
/// atividade sobe e desce, não como ela é desenhada.
@MainActor
protocol WorkoutActivityPresenting: AnyObject {
    /// Deixa a Live Activity de acordo com o treino: sobe quando começa,
    /// atualiza quando alguém sai, some quando não há treino iniciado.
    ///
    /// Idempotente de propósito: é chamado ao abrir o app também, para uma
    /// atividade perdida voltar e uma sobrando sumir.
    func sync(with workout: Workout?, partnerForID: (UUID) -> WorkoutPartner?)

    /// O treino acabou: mostra o tempo final parado e depois some.
    func finish(_ workout: Workout, partnerForID: (UUID) -> WorkoutPartner?)
}

/// Para testes e previews: não faz nada.
final class NoWorkoutActivity: WorkoutActivityPresenting {
    func sync(with _: Workout?, partnerForID _: (UUID) -> WorkoutPartner?) {}
    func finish(_: Workout, partnerForID _: (UUID) -> WorkoutPartner?) {}
}
