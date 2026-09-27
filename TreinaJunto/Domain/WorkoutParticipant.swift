import Foundation

/// Alguém dentro de um treino.
struct WorkoutParticipant: Identifiable, Hashable, Sendable {
    let profileID: UUID
    let isHost: Bool
    var joinedAt: Date
    /// Se apareceu de fato. Só é respondido ao encerrar o treino — até lá é
    /// `nil`, que quer dizer "ainda não sabemos", e não "faltou".
    var present: Bool?

    var id: UUID {
        profileID
    }

    init(profileID: UUID, isHost: Bool = false, joinedAt: Date = Date(), present: Bool? = nil) {
        self.profileID = profileID
        self.isHost = isHost
        self.joinedAt = joinedAt
        self.present = present
    }
}
