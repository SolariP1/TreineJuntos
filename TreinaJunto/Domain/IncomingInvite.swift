import Foundation

/// Convite que alguém mandou para você treinar junto.
struct IncomingInvite: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let sport: Sport
    let when: String
    let gradientIndex: Int

    init(id: UUID = UUID(), name: String, sport: Sport, when: String, gradientIndex: Int) {
        self.id = id
        self.name = name
        self.sport = sport
        self.when = when
        self.gradientIndex = gradientIndex
    }

    var initials: String {
        String(name.prefix(1))
    }
}
