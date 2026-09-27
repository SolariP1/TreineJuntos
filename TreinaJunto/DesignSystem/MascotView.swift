import SwiftUI

/// The app's little training buddy — a wobbling blob with a face. Drawn
/// entirely in SwiftUI so it can breathe, bounce and blink without assets.
struct MascotView: View {
    var color: Color
    var deepColor: Color
    var size: CGFloat = 92
    /// Mood changes the mouth: happy for wins, sleepy when idle.
    var mood: Mood = .happy

    enum Mood { case happy, cheer, sleepy }

    @State private var phase: CGFloat = 0
    @State private var bounce = false
    @State private var blinking = false

    var body: some View {
        ZStack {
            BlobShape(phase: phase, lobes: 5, amplitude: 0.09)
                .fill(
                    LinearGradient(
                        colors: [color, deepColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    BlobShape(phase: phase, lobes: 5, amplitude: 0.09)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                )

            VStack(spacing: size * 0.06) {
                HStack(spacing: size * 0.16) {
                    eye
                    eye
                }
                mouth
            }
            .offset(y: size * 0.04)
        }
        .frame(width: size, height: size)
        .offset(y: bounce ? -size * 0.05 : size * 0.05)
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                bounce = true
            }
            scheduleBlink()
        }
    }

    private var eye: some View {
        Capsule()
            .fill(Color(red: 0.11, green: 0.09, blue: 0.15))
            .frame(width: size * 0.09, height: size * 0.13)
            .scaleEffect(y: blinking ? 0.12 : 1, anchor: .center)
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .happy:
            SmileShape()
                .stroke(
                    Color(red: 0.11, green: 0.09, blue: 0.15),
                    style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round)
                )
                .frame(width: size * 0.22, height: size * 0.1)
        case .cheer:
            // Open, grinning mouth — kept wider than tall so it reads as a
            // laugh rather than a startled "O".
            Ellipse()
                .fill(Color(red: 0.11, green: 0.09, blue: 0.15))
                .frame(width: size * 0.2, height: size * 0.12)
        case .sleepy:
            Capsule()
                .fill(Color(red: 0.11, green: 0.09, blue: 0.15))
                .frame(width: size * 0.13, height: size * 0.035)
        }
    }

    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5 ... 5)) {
            withAnimation(.easeInOut(duration: 0.09)) { blinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.09)) { blinking = false }
                scheduleBlink()
            }
        }
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.8)
        )
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        MascotView(
            color: Playful.style(for: "Corrida").base,
            deepColor: Playful.style(for: "Corrida").deep,
            mood: .happy
        )
        MascotView(
            color: Playful.style(for: "Musculação").base,
            deepColor: Playful.style(for: "Musculação").deep,
            mood: .cheer
        )
        MascotView(
            color: Playful.style(for: "Natação").base,
            deepColor: Playful.style(for: "Natação").deep,
            mood: .sleepy
        )
    }
    .padding(40)
    .background(Playful.canvas)
}
