import SwiftUI

/// Como cada esporte se apresenta: nome que o usuário lê, cor e símbolo.
///
/// Mora no DesignSystem, não no Domain, porque `Sport` precisa continuar
/// sendo dado puro — compartilhável com servidor, widget ou watch sem
/// carregar SwiftUI junto.
extension Sport {
    var label: String {
        switch self {
        case .corrida: "Corrida"
        case .musculacao: "Musculação"
        case .funcional: "Funcional"
        case .ciclismo: "Ciclismo"
        case .yoga: "Yoga"
        case .natacao: "Natação"
        }
    }

    var ramp: ColorRamp {
        switch self {
        case .corrida: Palette.orange
        case .musculacao: Palette.violet
        case .funcional: Palette.mint
        case .ciclismo: Palette.amber
        case .yoga: Palette.pink
        case .natacao: Palette.sky
        }
    }

    var symbol: String {
        switch self {
        case .corrida: "figure.run"
        case .musculacao: "dumbbell.fill"
        case .funcional: "figure.strengthtraining.functional"
        case .ciclismo: "bicycle"
        case .yoga: "figure.yoga"
        case .natacao: "figure.pool.swim"
        }
    }

    var style: SportStyle {
        SportStyle(ramp: ramp, symbol: symbol)
    }
}

/// Identidade visual de uma modalidade: a cor dela mais o ícone.
struct SportStyle {
    let ramp: ColorRamp
    let symbol: String

    var base: Color {
        ramp.base
    }

    var soft: Color {
        ramp.soft
    }

    var deep: Color {
        ramp.deep
    }

    var gradient: LinearGradient {
        ramp.gradient
    }
}
