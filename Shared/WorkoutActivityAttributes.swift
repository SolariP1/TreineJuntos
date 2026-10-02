import ActivityKit
import Foundation

/// O que a Live Activity de um treino carrega (docs/PRODUTO.md §9.4).
///
/// Mora em `Shared/` porque é o contrato entre o app, que inicia a
/// atividade, e a extensão de widget, que a desenha. Não pode depender de
/// nada do app: a extensão não enxerga `Workout`, `Palette` nem as fontes.
struct WorkoutActivityAttributes: ActivityAttributes {
    /// O que muda durante o treino. Com servidor, é isto que o push leva.
    struct ContentState: Codable, Hashable {
        /// A única fonte do tempo. O relógio é sempre calculado daqui, nunca
        /// guardado — fechar o app ou reiniciar o celular não perde nada.
        var startedAt: Date
        /// Preenchido ao encerrar: a atividade mostra o tempo final parado.
        var finishedAt: Date?
        /// Iniciais de quem está no treino, na ordem das vagas.
        var participantInitials: [String]
    }

    let workoutID: UUID
    let sportName: String
    /// SF Symbol do esporte.
    let sportSymbol: String
    /// Cor do esporte em RGB, já que a extensão não tem a paleta do app.
    let tintRed: Double
    let tintGreen: Double
    let tintBlue: Double
    /// Academia ou lugar, quando houver.
    let place: String?
}
