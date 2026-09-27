import SwiftUI

/// Fileira de medalhas, levemente tortas. Igual no Perfil e no Portfólio.
struct BadgesStrip: View {
    let badges: [Badge]
    let appeared: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(badges.enumerated()), id: \.offset) { index, badge in
                    HStack(spacing: 6) {
                        Image(systemName: badge.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(badge.ramp.base)
                        Text(badge.label)
                            .font(.brand(11.5, weight: .bold))
                            .foregroundStyle(badge.ramp.deep)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(badge.ramp.soft, in: Capsule())
                    .overlay(Capsule().stroke(badge.ramp.base.opacity(0.25), lineWidth: 1))
                    .rotationEffect(.degrees(index % 2 == 0 ? -1.5 : 1.5))
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.6).delay(0.35 + Double(index) * 0.06),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}
