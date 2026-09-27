import Foundation

/// Como a distância em metros aparece na tela.
///
/// O modelo guarda metros porque o Feed precisa ordenar e filtrar por raio;
/// o texto curto que cabe num chip é decisão de apresentação.
enum DistanceFormatter {
    static func short(_ meters: Int) -> String {
        meters < 1000 ? "\(meters)m" : String(format: "%.1fkm", Double(meters) / 1000)
    }
}

extension WorkoutPartner {
    var distanceLabel: String {
        DistanceFormatter.short(distanceInMeters)
    }
}
