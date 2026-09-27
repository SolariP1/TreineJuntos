import Foundation

/// Uma pessoa que pode treinar com você.
struct WorkoutPartner: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let age: Int
    let sport: Sport
    /// Distância em metros. É número, não texto, porque o Feed precisa
    /// ordenar por proximidade e filtrar por raio — formatar é trabalho da
    /// apresentação.
    let distanceInMeters: Int
    /// Semente da cor do avatar enquanto a pessoa não tem foto.
    let gradientIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        sport: Sport,
        distanceInMeters: Int,
        gradientIndex: Int
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.sport = sport
        self.distanceInMeters = distanceInMeters
        self.gradientIndex = gradientIndex
    }

    var initials: String {
        String(name.prefix(1))
    }
}
