import SwiftUI

/// Gradiente do avatar enquanto a pessoa não tem foto.
///
/// Mora aqui, e não junto do modelo, para `Domain` seguir sem SwiftUI:
/// um parceiro de treino é um conceito de negócio e não precisa saber o
/// que é um `LinearGradient`.
enum Avatar {
    static func gradient(at index: Int) -> LinearGradient {
        Theme.avatarGradients[index % Theme.avatarGradients.count]
    }
}

extension WorkoutPartner {
    var gradient: LinearGradient {
        Avatar.gradient(at: gradientIndex)
    }
}

extension IncomingInvite {
    var gradient: LinearGradient {
        Avatar.gradient(at: gradientIndex)
    }
}

extension Review {
    var gradient: LinearGradient {
        Avatar.gradient(at: gradientIndex)
    }
}
