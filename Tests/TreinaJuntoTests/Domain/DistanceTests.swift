import Testing
@testable import TreinaJunto

@Suite("Domínio · Distância")
struct DistanceTests {
    @Test(
        "Abaixo de 1km aparece em metros; acima, em quilômetros",
        arguments: [
            (0, "0m"),
            (450, "450m"),
            (999, "999m"),
            (1000, "1.0km"),
            (1200, "1.2km"),
            (1500, "1.5km"),
            (12345, "12.3km")
        ]
    )
    func formatsByMagnitude(meters: Int, esperado: String) {
        #expect(DistanceFormatter.short(meters) == esperado)
    }

    @Test("Parceiros podem ser ordenados por proximidade")
    func partnersSortByProximity() {
        // A razão de distância ser número e não texto: ordenar "1.2km" como
        // String colocaria 1.2km antes de 450m.
        let ordenados = SampleData.partners
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
            .map(\.name)

        #expect(ordenados == ["Marina", "Lucas", "Beatriz", "Rafael"])
    }

    @Test("Dá para filtrar quem está dentro de um raio")
    func partnersFilterByRadius() {
        let ateUmKm = SampleData.partners.filter { $0.distanceInMeters <= 1000 }
        #expect(ateUmKm.count == 2)
    }
}
