import Foundation

/// O perfil de quem está usando o app.
struct UserProfile: Hashable, Sendable {
    var name: String
    var city: String
    var bio: String
    var trainings: Int
    var partners: Int
    var rating: String
    var sports: [Sport]
    var trainingInterests: [String]
    /// Fotos escolhidas no aparelho, vazias até a pessoa adicionar as dela.
    var photos: [Data]
    var weeklySplit: [WorkoutDay]
    var reviews: [Review]
}

/// Etiquetas de preferência que a pessoa marca no perfil.
///
/// Ainda são texto solto, ao contrário de `Sport`. Vira enum quando a busca
/// por afinidade precisar comparar interesse com interesse.
let availableInterests = [
    "Treino matinal", "Treino noturno", "Parceiro fixo",
    "Nível iniciante", "Nível intermediário", "Nível avançado",
    "Foco em hipertrofia", "Foco em resistência", "Grupo/comunidade"
]
