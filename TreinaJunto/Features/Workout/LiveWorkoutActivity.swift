import ActivityKit
import SwiftUI
import UIKit

/// A Live Activity de verdade, pelo ActivityKit.
///
/// Só sobe no aparelho de quem está com o app aberto. Nos convidados, ela
/// precisa subir por push-to-start, que depende de servidor e de iOS 17.2
/// (docs/PRODUTO.md §9.4).
@MainActor
final class LiveWorkoutActivity: WorkoutActivityPresenting {
    /// Uma só no app: as atividades são do sistema, não de uma tela.
    static let shared = LiveWorkoutActivity()

    /// Quanto tempo o tempo final fica na tela depois de encerrar.
    private let finishedLinger: TimeInterval = 5 * 60

    func sync(with workout: Workout?, partnerForID: (UUID) -> WorkoutPartner?) {
        guard let workout, workout.status == .started, let inicio = workout.startedAt else {
            endAll(except: nil)
            return
        }
        // Um treino ativo por vez: qualquer atividade de outro treino é resto.
        endAll(except: workout.id)

        let estado = state(for: workout, startedAt: inicio, partnerForID: partnerForID)
        if let atual = current(for: workout.id) {
            Task { await atual.update(ActivityContent(state: estado, staleDate: nil)) }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        _ = try? Activity.request(
            attributes: attributes(for: workout),
            content: ActivityContent(state: estado, staleDate: nil),
            pushType: nil
        )
    }

    func finish(_ workout: Workout, partnerForID: (UUID) -> WorkoutPartner?) {
        guard let atividade = current(for: workout.id), let inicio = workout.startedAt else { return }
        var estado = state(for: workout, startedAt: inicio, partnerForID: partnerForID)
        estado.finishedAt = workout.finishedAt ?? Date()
        let some = Date().addingTimeInterval(finishedLinger)
        Task {
            await atividade.end(ActivityContent(state: estado, staleDate: nil), dismissalPolicy: .after(some))
        }
    }

    // MARK: - Apoio

    private func current(for workoutID: UUID) -> Activity<WorkoutActivityAttributes>? {
        Activity<WorkoutActivityAttributes>.activities.first { $0.attributes.workoutID == workoutID }
    }

    private func endAll(except workoutID: UUID?) {
        let sobrando = Activity<WorkoutActivityAttributes>.activities.filter {
            $0.attributes.workoutID != workoutID
        }
        for atividade in sobrando {
            Task { await atividade.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private func attributes(for workout: Workout) -> WorkoutActivityAttributes {
        // A extensão não tem a paleta: a cor vai em RGB, lida da própria
        // paleta para as duas nunca divergirem.
        var vermelho: CGFloat = 0, verde: CGFloat = 0, azul: CGFloat = 0, alfa: CGFloat = 0
        UIColor(workout.sport.style.base).getRed(&vermelho, green: &verde, blue: &azul, alpha: &alfa)
        return WorkoutActivityAttributes(
            workoutID: workout.id,
            sportName: workout.sport.label,
            sportSymbol: workout.sport.style.symbol,
            tintRed: Double(vermelho),
            tintGreen: Double(verde),
            tintBlue: Double(azul),
            place: workout.gym
        )
    }

    private func state(
        for workout: Workout,
        startedAt: Date,
        partnerForID: (UUID) -> WorkoutPartner?
    ) -> WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            startedAt: startedAt,
            finishedAt: nil,
            participantInitials: workout.participants.map { participante in
                if participante.profileID == SampleData.meID {
                    return "Eu"
                }
                return partnerForID(participante.profileID)?.initials ?? "?"
            }
        )
    }
}
