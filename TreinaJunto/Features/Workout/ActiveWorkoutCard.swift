import SwiftUI

/// O treino que está de pé, no topo do Feed.
///
/// Enquanto aberto, mostra quantas vagas faltam. É o lugar de onde a Live
/// Activity vai nascer quando o treino for iniciado.
struct ActiveWorkoutCard: View {
    let workout: Workout
    var onCancel: () -> Void

    private var style: SportStyle {
        workout.sport.style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: style.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.22), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.isParty ? "Party aberta" : "Treino aberto")
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(workout.sport.label)
                        .font(.brand(12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.pressable)
            }

            Text(vagas)
                .font(.brand(12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white.opacity(0.18), in: Capsule())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 20, y: 12)
    }

    private var vagas: String {
        switch workout.freeSpots {
        case 0: "Cheio — \(workout.participants.count) confirmados"
        case 1: "Falta 1 pessoa"
        case let n: "Faltam \(n) pessoas"
        }
    }
}

#Preview {
    if let treino = try? Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: 4) {
        ActiveWorkoutCard(workout: treino, onCancel: {})
            .padding()
    }
}
