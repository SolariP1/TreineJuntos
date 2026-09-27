import SwiftUI

struct PersonCardView: View {
    let person: WorkoutPartner
    let isInvited: Bool
    var onInvite: () -> Void
    var onOpenProfile: () -> Void

    private var style: SportStyle {
        person.sport.style
    }

    var body: some View {
        HStack(spacing: 12) {
            // The identity area opens the portfolio; the invite button stays
            // its own control so the two gestures never fight.
            Button(action: onOpenProfile) {
                HStack(spacing: 12) {
                    ZStack {
                        BlobShape(phase: CGFloat(person.gradientIndex) * 1.1, lobes: 5, amplitude: 0.08)
                            .fill(style.base.opacity(0.3))
                            .frame(width: 58, height: 58)
                        Circle()
                            .fill(style.gradient)
                            .frame(width: 46, height: 46)
                        Text(person.initials)
                            .font(.display(16))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(person.name), \(person.age)")
                            .font(.brand(14.5, weight: .bold))
                            .foregroundStyle(Playful.ink)
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: style.symbol).font(.system(size: 9, weight: .semibold))
                                Text(person.sport.label).font(.brand(10.5, weight: .bold))
                            }
                            .foregroundStyle(style.deep)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(.white.opacity(0.8), in: Capsule())

                            Text(person.distanceLabel)
                                .font(.mono(10.5, weight: .medium))
                                .foregroundStyle(Playful.inkMuted)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)

            Button(action: onInvite) {
                Group {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    } else {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(width: 46, height: 46)
            }
            .foregroundStyle(isInvited ? style.deep : .white)
            .background(
                isInvited ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(style.base),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .disabled(isInvited)
            .buttonStyle(.pressable)
        }
        .padding(13)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 16, y: 8)
    }
}
