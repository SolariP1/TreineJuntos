import SwiftUI

/// Esportes e interesses do perfil, em etiquetas.
struct ProfileInterestsCard: View {
    let sports: [Sport]
    let interests: [String]
    let style: SportStyle
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("O que procuro")
                Spacer()
                Button("Editar", action: onEdit)
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(style.deep)
            }

            FlowLayout(spacing: 7) {
                ForEach(sports, id: \.self) { sport in
                    let sportStyle = sport.style
                    HStack(spacing: 5) {
                        Image(systemName: sportStyle.symbol).font(.system(size: 9.5, weight: .semibold))
                        Text(sport.label).font(.brand(11.5, weight: .bold))
                    }
                    .foregroundStyle(sportStyle.deep)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(sportStyle.soft, in: Capsule())
                }

                ForEach(interests, id: \.self) { interest in
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle").font(.system(size: 9))
                        Text(interest).font(.brand(11.5, weight: .semibold))
                    }
                    .foregroundStyle(Playful.inkMuted)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Playful.canvas, in: Capsule())
                }
            }
        }
        .padding(18)
        .playfulCard()
    }
}
