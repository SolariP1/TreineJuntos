import SwiftUI

/// O que o parceiro procura num treino, em etiquetas.
struct PortfolioInterestsCard: View {
    let interests: [String]
    let style: SportStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("O que procura")
            FlowLayout(spacing: 7) {
                ForEach(interests, id: \.self) { interest in
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle").font(.system(size: 9))
                        Text(interest).font(.brand(11.5, weight: .semibold))
                    }
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(style.soft, in: Capsule())
                }
            }
        }
        .padding(18)
        .playfulCard()
    }
}
