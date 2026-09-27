import SwiftUI

enum Playful {
    static let canvas = Color(red: 0.965, green: 0.961, blue: 0.976)
    static let surface = Color.white
    static let ink = Color(red: 0.106, green: 0.094, blue: 0.145)
    static let inkMuted = Color(red: 0.435, green: 0.420, blue: 0.494)
    static let inkFaint = Color(red: 0.667, green: 0.655, blue: 0.706)
    static let hairline = Color(red: 0.902, green: 0.898, blue: 0.925)
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
