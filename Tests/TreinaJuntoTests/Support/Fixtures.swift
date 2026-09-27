import Foundation
@testable import TreinaJunto

/// Dados de teste compartilhados. Um lugar só para construir objetos de
/// domínio, para que uma mudança de assinatura quebre um arquivo, não trinta.
enum Fixtures {
    static func partner(
        name: String = "Marina",
        age: Int = 27,
        sport: Sport = .corrida,
        distanceInMeters: Int = 450,
        gradientIndex: Int = 0
    ) -> WorkoutPartner {
        WorkoutPartner(
            name: name,
            age: age,
            sport: sport,
            distanceInMeters: distanceInMeters,
            gradientIndex: gradientIndex
        )
    }

    static func profile() -> UserProfile {
        SampleData.profile
    }
}
