import Foundation

/// Avaliação que um parceiro deixou depois de um treino.
struct Review: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let reviewerName: String
    let rating: Int
    let comment: String
    let context: String
    let gradientIndex: Int

    init(
        id: UUID = UUID(),
        reviewerName: String,
        rating: Int,
        comment: String,
        context: String,
        gradientIndex: Int
    ) {
        self.id = id
        self.reviewerName = reviewerName
        self.rating = rating
        self.comment = comment
        self.context = context
        self.gradientIndex = gradientIndex
    }

    var initials: String {
        String(reviewerName.prefix(1))
    }
}
