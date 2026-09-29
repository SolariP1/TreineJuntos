import SwiftUI

struct InviteCardView: View {
    let received: ReceivedInvite
    var onAccept: () -> Void
    var onDecline: () -> Void

    private var style: SportStyle {
        received.workout.sport.style
    }

    private var partner: WorkoutPartner {
        received.from
    }

    private var workout: Workout {
        received.workout
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                ZStack {
                    Circle().fill(partner.gradient)
                    Text(partner.initials).font(.display(14)).foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(partner.name)
                        .font(.brand(13.5, weight: .bold))
                        .foregroundStyle(Playful.ink)
                    HStack(spacing: 4) {
                        Image(systemName: style.symbol).font(.system(size: 8, weight: .semibold))
                        Text(workout.sport.label).font(.brand(9.5, weight: .bold))
                    }
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.white.opacity(0.75), in: Capsule())
                }
                Spacer(minLength: 0)
            }

            Text(quando)
                .font(.brand(11, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(Playful.inkMuted)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(.white)
                .background(style.base, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)
            }
        }
        .padding(13)
        .frame(width: 196)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 14, y: 8)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    /// Quando é o treino, e — quando for party — com quanta gente.
    private var quando: String {
        let horario = workout.scheduledFor.map(Self.formatter.string(from:)) ?? "agora"
        guard workout.isParty else { return horario }
        return "\(horario) · party de \(workout.maxParticipants)"
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    if let treino = try? Workout(hostID: UUID(), sport: .corrida, scheduledFor: Date()) {
        InviteCardView(
            received: ReceivedInvite(
                invite: WorkoutInvite(
                    workoutID: treino.id,
                    fromProfileID: treino.hostID,
                    toProfileID: SampleData.meID
                ),
                from: SampleData.partners[0],
                workout: treino
            ),
            onAccept: {},
            onDecline: {}
        )
        .padding()
    }
}
