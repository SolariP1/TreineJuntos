import SwiftUI

/// O cartão colorido do topo do portfólio: avatar, nome, esporte, distância,
/// bio e a etiqueta de compatibilidade.
struct PortfolioHeroCard: View {
    let partner: WorkoutPartner
    let bio: String
    let compatibility: Int
    let style: SportStyle
    let statsRevealed: Bool

    var body: some View {
        ZStack {
            FloatingBlob(color: .white.opacity(0.18), size: 210, lobes: 6, speed: 11)
                .offset(x: -110, y: -50)
            FloatingBlob(color: .white.opacity(0.12), size: 150, lobes: 4, speed: 8)
                .offset(x: 120, y: 60)

            VStack(spacing: 14) {
                ZStack {
                    BlobShape(phase: 0.9, lobes: 6, amplitude: 0.07)
                        .fill(.white.opacity(0.28))
                        .frame(width: 116, height: 116)
                    Circle()
                        .fill(partner.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 4))
                    Text(partner.initials)
                        .font(.display(34))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("\(partner.name), \(partner.age)")
                        .font(.display(24, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        tag(symbol: style.symbol, text: partner.sport.label)
                        tag(symbol: "location.fill", text: partner.distanceLabel)
                    }

                    if !bio.isEmpty {
                        Text(bio)
                            .font(.brand(12.5))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                    }
                }

                compatibilityPill
            }
            .padding(.vertical, 26)
        }
        .frame(maxWidth: .infinity)
        .background(style.gradient, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 24, y: 14)
    }

    private func tag(symbol: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
            Text(text).font(.brand(11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.22), in: Capsule())
    }

    private var compatibilityPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(style.deep)
            Text("\(statsRevealed ? compatibility : 0)% compatível com você")
                .font(.brand(12.5, weight: .bold))
                .foregroundStyle(style.deep)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.white, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }
}
