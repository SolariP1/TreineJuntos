import SwiftUI

/// Lista de avaliações com avatar, estrelas e comentário. Igual no Perfil e
/// no Portfólio.
struct ReviewsList: View {
    let reviews: [Review]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(reviews) { review in
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle().fill(review.gradient)
                        Text(review.initials).font(.display(12)).foregroundStyle(.white)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(review.reviewerName)
                                .font(.brand(12.5, weight: .bold))
                                .foregroundStyle(Playful.ink)
                            StarRating(rating: review.rating)
                        }
                        Text(review.comment)
                            .font(.brand(11.5))
                            .foregroundStyle(Playful.inkMuted)
                        Text(review.context)
                            .font(.brand(9.5, weight: .medium))
                            .foregroundStyle(Playful.inkFaint)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    Playful.canvas.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
    }
}

/// Cinco estrelas, preenchidas até a nota.
struct StarRating: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0 ..< 5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(Palette.amber.base)
            }
        }
    }
}

/// A nota média como etiqueta, no cabeçalho do card de avaliações.
struct RatingPill: View {
    let rating: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").font(.system(size: 11))
            Text(rating).font(.mono(12, weight: .bold))
        }
        .foregroundStyle(Palette.amber.deep)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Palette.amber.soft, in: Capsule())
    }
}
