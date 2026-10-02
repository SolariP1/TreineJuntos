import SwiftUI

/// O convite de treino dentro da conversa: o treino, as vagas e, para quem
/// foi chamado, Aceitar e Recusar.
struct WorkoutInviteMessageCard: View {
    let workout: Workout
    let state: WorkoutInviteCardState
    var onRespond: (Bool) -> Void

    private var style: SportStyle {
        workout.sport.style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: style.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(style.base, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.isParty ? "Party de \(workout.sport.label)" : workout.sport.label)
                        .font(.brand(14, weight: .bold))
                        .foregroundStyle(Playful.ink)
                    Text(subtitle)
                        .font(.brand(11.5))
                        .foregroundStyle(Playful.inkMuted)
                }
            }

            if case .canRespond = state {
                HStack(spacing: 8) {
                    Button { onRespond(false) } label: {
                        Text("Recusar")
                            .font(.brand(13, weight: .bold))
                            .foregroundStyle(Playful.inkMuted)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(Playful.canvas, in: Capsule())
                    }
                    Button { onRespond(true) } label: {
                        Text("Aceitar")
                            .font(.brand(13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(style.base, in: Capsule())
                    }
                }
                .buttonStyle(.pressable)
            } else {
                Text(state.caption)
                    .font(.brand(12, weight: .semibold))
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(style.soft, in: Capsule())
            }
        }
        .padding(14)
        .frame(width: 250, alignment: .leading)
        .background(Playful.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style.base.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private var subtitle: String {
        let pessoas = "\(workout.participants.count) de \(workout.maxParticipants)"
        let horario = workout.scheduledFor.map(Self.formatter.string(from:)) ?? "Agora"
        return "\(horario) · \(pessoas)"
    }

    /// O mesmo formato do card de convite do Feed: "Hoje, 07:00".
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
