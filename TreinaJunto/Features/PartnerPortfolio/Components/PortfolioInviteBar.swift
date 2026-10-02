import SwiftUI

/// A barra fixa no rodapé do portfólio, com a curtida.
///
/// Curtir, e não convidar: o convite para treino sai da conversa, que nasce
/// da curtida mútua (docs/PRODUTO.md §9).
struct PortfolioInviteBar: View {
    let partnerName: String
    let style: SportStyle
    var onInvite: () -> Void

    var body: some View {
        Button(action: onInvite) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill").font(.system(size: 14, weight: .semibold))
                Text("Curtir \(partnerName)")
                    .font(.brand(15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .background(
            LinearGradient(colors: [style.base, style.deep], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: style.base.opacity(0.4), radius: 16, y: 8)
        .buttonStyle(.pressable)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
    }
}
