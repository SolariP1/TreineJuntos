import SwiftUI

@main
struct TreinaJuntoApp: App {
    /// Composição da raiz: o único ponto do app que escolhe implementações.
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dependencies, dependencies)
        }
    }
}
