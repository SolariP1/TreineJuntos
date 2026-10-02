import Foundation

/// Uma foto tirada durante um treino (docs/PRODUTO.md §10.1).
struct WorkoutPhoto: Identifiable, Hashable, Sendable {
    /// Somando todos os participantes. Provisório: é o limite que o backlog
    /// deixou em aberto, e o que segura o Storage do plano gratuito.
    static let limitPerWorkout = 20

    let id: UUID
    let workoutID: UUID
    let authorID: UUID
    /// JPEG já comprimido no aparelho. Com servidor, vira o caminho no
    /// Storage — a imagem não vai para o banco.
    let imageData: Data
    let createdAt: Date

    init(
        id: UUID = UUID(),
        workoutID: UUID,
        authorID: UUID,
        imageData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.authorID = authorID
        self.imageData = imageData
        self.createdAt = createdAt
    }
}

enum WorkoutPhotoError: Error, Equatable {
    /// Treino aberto ainda não aconteceu; encerrado já acabou.
    case workoutNotStarted
    case notAParticipant
    case limitReached
    case emptyImage
}
