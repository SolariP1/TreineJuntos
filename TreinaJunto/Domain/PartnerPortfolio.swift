import Foundation

/// O que aconteceu num dia do calendário de treinos de alguém.
enum TrainingDayState: Sendable {
    /// Nada marcado.
    case idle
    /// Abriu um treino, mas ninguém apareceu.
    case openedAlone
    /// Treinou com um parceiro.
    case trainedTogether
}

/// Tudo o que aparece no portfólio público de um parceiro.
struct PartnerPortfolio: Identifiable, Hashable, Sendable {
    let id: UUID
    let partner: WorkoutPartner
    let bio: String
    /// 0–100, afinidade por esporte, horário e nível em comum.
    let compatibility: Int
    let streak: Int
    let totalTrainings: Int
    /// % dos treinos abertos em que a pessoa realmente apareceu.
    let reliability: Int
    let rating: String
    let sports: [Sport]
    let interests: [String]
    let weeklySplit: [WorkoutDay]
    let reviews: [Review]
    /// Dia do mês → o que aconteceu nele.
    let days: [Int: TrainingDayState]
    /// Dia do mês → com quem treinou (inicial), quando se aplica.
    let dayPartners: [Int: String]

    init(
        id: UUID = UUID(),
        partner: WorkoutPartner,
        bio: String,
        compatibility: Int,
        streak: Int,
        totalTrainings: Int,
        reliability: Int,
        rating: String,
        sports: [Sport],
        interests: [String],
        weeklySplit: [WorkoutDay],
        reviews: [Review],
        days: [Int: TrainingDayState],
        dayPartners: [Int: String]
    ) {
        self.id = id
        self.partner = partner
        self.bio = bio
        self.compatibility = compatibility
        self.streak = streak
        self.totalTrainings = totalTrainings
        self.reliability = reliability
        self.rating = rating
        self.sports = sports
        self.interests = interests
        self.weeklySplit = weeklySplit
        self.reviews = reviews
        self.days = days
        self.dayPartners = dayPartners
    }
}
