import SwiftUI

struct OnboardingView: View {
    var onSignIn: (SignInMethod) -> Void

    @State private var ringsExpanded = false
    @State private var runnerBob = false
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            heroArt
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)

            VStack(alignment: .leading, spacing: 12) {
                Text("Nunca mais treine sozinho.")
                    .font(.display(27))
                    .foregroundStyle(Theme.ink)

                Text("Conectamos você a quem treina no mesmo bairro, no mesmo horário, com o mesmo objetivo.")
                    .font(.brand(14.5))
                    .foregroundStyle(Theme.inkMuted)

                Spacer().frame(height: 22)

                signInOptions

                Text("Ao continuar, você aceita nossos Termos de Uso e Política de Privacidade.")
                    .font(.brand(11))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 20)

            Spacer(minLength: 24)
        }
        .background(Theme.screenBackground)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) {
                contentAppeared = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                ringsExpanded = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                runnerBob = true
            }
        }
    }

    // MARK: - Sign-in options

    private var signInOptions: some View {
        VStack(spacing: 10) {
            Button { onSignIn(.apple) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                    Text("Continuar com Apple")
                }
                .font(.brand(15.5, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .foregroundStyle(Theme.screenBackground)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .buttonStyle(.pressable)

            Button { onSignIn(.google) } label: {
                HStack(spacing: 10) {
                    GoogleGlyph()
                    Text("Continuar com Google")
                }
                .font(.brand(15.5, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .foregroundStyle(Theme.ink)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1.5)
            )
            .buttonStyle(.pressable)

            Button { onSignIn(.email) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                    Text("Continuar com e-mail")
                }
                .font(.brand(14.5, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .foregroundStyle(Theme.inkMuted)
            .buttonStyle(.pressable)
        }
    }

    // MARK: - Hero art

    private var heroArt: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Theme.accent, Color(red: 0.788, green: 0.239, blue: 0.071)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.28), lineWidth: 2)
                        .frame(width: ringsExpanded ? 246 : 220, height: ringsExpanded ? 246 : 220)
                        .opacity(ringsExpanded ? 0.15 : 0.3)
                        .offset(x: -110, y: 90)
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 2)
                        .frame(width: ringsExpanded ? 160 : 140, height: ringsExpanded ? 160 : 140)
                        .opacity(ringsExpanded ? 0.12 : 0.22)
                        .offset(x: 110, y: -100)

                    ForEach(0 ..< 3) { i in
                        Circle()
                            .fill(.white.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .offset(x: CGFloat(-40 + i * 34), y: runnerBob ? -8 : 6)
                            .opacity(runnerBob ? 0.15 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.18),
                                value: runnerBob
                            )
                            .offset(x: 0, y: -30)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

            Image(systemName: "figure.run")
                .font(.brand(78))
                .foregroundStyle(.white)
                .padding(24)
                .offset(y: runnerBob ? -6 : 4)
                .rotationEffect(.degrees(runnerBob ? -3 : 3), anchor: .bottom)
        }
        .frame(height: 340)
        .shadow(color: Theme.accent.opacity(0.35), radius: 30, y: 18)
        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: runnerBob)
    }
}

/// Lightweight stand-in for the Google "G" mark — swap for the official
/// GoogleSignIn button asset when wiring up real Google auth.
private struct GoogleGlyph: View {
    var body: some View {
        Text("G")
            .font(.brand(15, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.259, green: 0.522, blue: 0.957),
                        Color(red: 0.918, green: 0.263, blue: 0.208),
                        Color(red: 0.984, green: 0.737, blue: 0.020),
                        Color(red: 0.204, green: 0.659, blue: 0.325)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    OnboardingView { _ in }
}
