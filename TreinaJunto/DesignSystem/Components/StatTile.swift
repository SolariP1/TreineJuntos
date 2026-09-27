import SwiftUI

/// Um número grande com ícone e legenda.
///
/// Perfil e Portfólio tinham cada um a sua versão; a do Portfólio levava seis
/// parâmetros, um a mais que o limite do projeto. Aqui `pulses` tem valor
/// padrão, então quem não anima nem precisa mencionar.
struct StatTile: View {
    let value: Int
    var suffix: String = ""
    let label: String
    let symbol: String
    let color: Color
    var pulses: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            icon
            Text("\(value)\(suffix)")
                .font(.mono(19, weight: .bold))
                .foregroundStyle(Playful.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.brand(10, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .playfulCard(Playful.surface, radius: 22, tint: color)
    }

    @ViewBuilder
    private var icon: some View {
        if pulses {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .phaseAnimator([1.0, 1.18]) { content, scale in
                    content.scaleEffect(scale)
                } animation: { _ in .easeInOut(duration: 0.9) }
        } else {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(color)
        }
    }
}

/// A nota média, que mostra texto em vez de número inteiro.
struct RatingTile: View {
    let rating: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.amber.base)
            Text(rating)
                .font(.mono(19, weight: .bold))
                .foregroundStyle(Playful.ink)
            Text("nota")
                .font(.brand(10, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .playfulCard(Playful.surface, radius: 22, tint: Palette.amber.base)
    }
}
