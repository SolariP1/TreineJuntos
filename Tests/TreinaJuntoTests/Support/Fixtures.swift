import Foundation
@testable import TreinaJunto

/// Dados de teste compartilhados. Um lugar só para construir objetos de
/// domínio, para que uma mudança de assinatura quebre um arquivo, não trinta.
enum Fixtures {
    static func partner(
        name: String = "Marina",
        age: Int = 27,
        sport: Sport = .corrida,
        distance: String = "450m",
        gradientIndex: Int = 0
    ) -> WorkoutPartner {
        WorkoutPartner(
            name: name,
            age: age,
            sport: sport,
            distance: distance,
            gradientIndex: gradientIndex
        )
    }

    static func profile() -> UserProfile {
        UserProfile()
    }
}
