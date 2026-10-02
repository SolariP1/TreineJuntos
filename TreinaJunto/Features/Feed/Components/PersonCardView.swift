import SwiftUI

struct PersonCardView: View {
    let person: WorkoutPartner
    let isLiked: Bool
    var onLike: () -> Void
    var onOpenProfile: () -> Void

    private var style: SportStyle {
        person.sport.style
    }

    var body: some View {
        HStack(spacing: 12) {
            // The identity area opens the portfolio; the like button stays
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

            // Curtir, não convidar: o convite para treino sai da conversa,
            // que só existe depois da curtida mútua (docs/PRODUTO.md §9).
            Button(action: onLike) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 46, height: 46)
            }
            .foregroundStyle(isLiked ? style.deep : .white)
            .background(
                isLiked ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(style.base),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .disabled(isLiked)
            .accessibilityLabel(isLiked ? "Você curtiu \(person.name)" : "Curtir \(person.name)")
            .buttonStyle(.pressable)
        }
        .padding(13)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 16, y: 8)
    }
}
