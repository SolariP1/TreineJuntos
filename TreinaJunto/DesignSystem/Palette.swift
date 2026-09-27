import SwiftUI

/// Três tons de uma mesma cor: o cheio, o lavado para fundo e o escuro para
/// texto sobre o lavado.
struct ColorRamp: Hashable {
    let base: Color
    let soft: Color
    let deep: Color

    var gradient: LinearGradient {
        LinearGradient(
            colors: [base, deep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// As cores do app.
///
/// Separada de `Sport`: antes existia uma tabela só, e pedir a cor de
/// "Corrida" era como o código dizia "laranja" — o que fazia a cor da tab bar
/// e a das medalhas mudarem junto com a identidade de um esporte. Aqui ficam
/// as cores enquanto cores; a identidade visual de cada modalidade fica em
/// `Sport.style`.
enum Palette {
    static let orange = ColorRamp(
        base: Color(red: 1.000, green: 0.439, blue: 0.263),
        soft: Color(red: 1.000, green: 0.902, blue: 0.871),
        deep: Color(red: 0.788, green: 0.286, blue: 0.145)
    )

    static let violet = ColorRamp(
        base: Color(red: 0.655, green: 0.545, blue: 0.980),
        soft: Color(red: 0.929, green: 0.906, blue: 0.996),
        deep: Color(red: 0.459, green: 0.353, blue: 0.812)
    )

    static let mint = ColorRamp(
        base: Color(red: 0.204, green: 0.827, blue: 0.600),
        soft: Color(red: 0.847, green: 0.965, blue: 0.918),
        deep: Color(red: 0.086, green: 0.612, blue: 0.435)
    )

    static let amber = ColorRamp(
        base: Color(red: 0.984, green: 0.749, blue: 0.141),
        soft: Color(red: 0.996, green: 0.941, blue: 0.808),
        deep: Color(red: 0.792, green: 0.553, blue: 0.055)
    )

    static let pink = ColorRamp(
        base: Color(red: 0.957, green: 0.447, blue: 0.714),
        soft: Color(red: 0.992, green: 0.894, blue: 0.941),
        deep: Color(red: 0.757, green: 0.259, blue: 0.525)
    )

    static let sky = ColorRamp(
        base: Color(red: 0.220, green: 0.741, blue: 0.973),
        soft: Color(red: 0.863, green: 0.941, blue: 0.992),
        deep: Color(red: 0.094, green: 0.545, blue: 0.788)
    )

    /// Cor de ação do app — botão principal, seleção, destaque.
    static let accent = orange
}
