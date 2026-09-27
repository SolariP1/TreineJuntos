import Foundation

/// Um dia da rotina semanal de treino.
struct WorkoutDay: Identifiable, Hashable, Sendable {
    let id: UUID
    let day: String
    let focus: String
    let exercises: [String]

    init(id: UUID = UUID(), day: String, focus: String, exercises: [String]) {
        self.id = id
        self.day = day
        self.focus = focus
        self.exercises = exercises
    }
}
