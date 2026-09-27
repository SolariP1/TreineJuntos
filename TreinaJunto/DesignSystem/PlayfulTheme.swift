import SwiftUI

/// Playful design system: every sport carries its own colour, so colour does
/// double duty as decoration *and* as information.
struct SportStyle {
    let base: Color
    let soft: Color
    let deep: Color
    let symbol: String
}

enum Playful {
    static let canvas = Color(red: 0.965, green: 0.961, blue: 0.976)
    static let surface = Color.white
    static let ink = Color(red: 0.106, green: 0.094, blue: 0.145)
    static let inkMuted = Color(red: 0.435, green: 0.420, blue: 0.494)
    static let inkFaint = Color(red: 0.667, green: 0.655, blue: 0.706)
    static let hairline = Color(red: 0.902, green: 0.898, blue: 0.925)

    /// Estilo usado quando o esporte não está no catálogo — a lista de
    /// esportes vai crescer no servidor antes de crescer aqui, então um
    /// desconhecido precisa desenhar em vez de quebrar.
    static let fallbackStyle = SportStyle(
        base: Color(red: 1.000, green: 0.439, blue: 0.263),
        soft: Color(red: 1.000, green: 0.902, blue: 0.871),
        deep: Color(red: 0.788, green: 0.286, blue: 0.145),
        symbol: "figure.run"
    )

    static let sportStyles: [String: SportStyle] = [
        "Corrida": fallbackStyle,
        "Musculação": SportStyle(
            base: Color(red: 0.655, green: 0.545, blue: 0.980),
            soft: Color(red: 0.929, green: 0.906, blue: 0.996),
            deep: Color(red: 0.459, green: 0.353, blue: 0.812),
            symbol: "dumbbell.fill"
        ),
        "Funcional": SportStyle(
            base: Color(red: 0.204, green: 0.827, blue: 0.600),
            soft: Color(red: 0.847, green: 0.965, blue: 0.918),
            deep: Color(red: 0.086, green: 0.612, blue: 0.435),
            symbol: "figure.strengthtraining.functional"
        ),
        "Ciclismo": SportStyle(
            base: Color(red: 0.984, green: 0.749, blue: 0.141),
            soft: Color(red: 0.996, green: 0.941, blue: 0.808),
            deep: Color(red: 0.792, green: 0.553, blue: 0.055),
            symbol: "bicycle"
        ),
        "Yoga": SportStyle(
            base: Color(red: 0.957, green: 0.447, blue: 0.714),
            soft: Color(red: 0.992, green: 0.894, blue: 0.941),
            deep: Color(red: 0.757, green: 0.259, blue: 0.525),
            symbol: "figure.yoga"
        ),
        "Natação": SportStyle(
            base: Color(red: 0.220, green: 0.741, blue: 0.973),
            soft: Color(red: 0.863, green: 0.941, blue: 0.992),
            deep: Color(red: 0.094, green: 0.545, blue: 0.788),
            symbol: "figure.pool.swim"
        )
    ]

    static func style(for sport: String) -> SportStyle {
        sportStyles[sport] ?? fallbackStyle
    }
}

extension SportStyle {
    /// Avatar/hero gradient in this sport's own hue, so a card reads as one
    /// colour family instead of clashing with a random avatar colour.
    var gradient: LinearGradient {
        LinearGradient(colors: [base, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Blob

/// Organic wobbling shape — the closest thing to the 3D blobs in the
/// reference designs that can be drawn (and animated) entirely in code.
struct BlobShape: Shape {
    var phase: CGFloat
    var lobes: Int = 5
    var amplitude: CGFloat = 0.10

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        let steps = 160
        var path = Path()

        for step in 0 ... steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let angle = progress * 2 * .pi
            let wobble = sin(angle * CGFloat(lobes) + phase) * amplitude
                + cos(angle * CGFloat(max(lobes - 2, 1)) - phase * 0.7) * (amplitude * 0.45)
            let radius = baseRadius * (1 + wobble)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// A blob that breathes and drifts forever — used as background decoration.
struct FloatingBlob: View {
    var color: Color
    var size: CGFloat
    var lobes: Int = 5
    var speed: Double = 9
    var blur: CGFloat = 0

    @State private var phase: CGFloat = 0
    @State private var drift = false

    var body: some View {
        BlobShape(phase: phase, lobes: lobes)
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(y: drift ? -8 : 8)
            .onAppear {
                withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
                withAnimation(.easeInOut(duration: speed / 3).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
    }
}

// MARK: - Card

extension View {
    /// Chunky rounded card with a shadow tinted by its own hue — the base
    /// surface of the playful system.
    func playfulCard(
        _ fill: Color = Playful.surface,
        radius: CGFloat = 28,
        tint: Color = .black
    ) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: tint.opacity(0.10), radius: 18, y: 10)
    }
}
