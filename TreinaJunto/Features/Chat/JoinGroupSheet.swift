import SwiftUI

/// A prévia de um grupo aberto por link.
///
/// O link é o único caminho em que alguém entra numa conversa sem curtida
/// mútua, então a pessoa vê onde está entrando e decide — tocar no link não
/// põe ninguém em grupo nenhum (docs/PRODUTO.md §9.2).
struct JoinGroupSheet: View {
    let summary: ConversationSummary
    var onJoin: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            ConversationAvatar(summary: summary, size: 76)
                .padding(.top, 28)

            VStack(spacing: 4) {
                Text(summary.title)
                    .font(.display(20, weight: .bold))
                    .foregroundStyle(Playful.ink)
                Text(membersLine)
                    .font(.brand(12.5))
                    .foregroundStyle(Playful.inkMuted)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)

            Button {
                onJoin()
                dismiss()
            } label: {
                Text("Entrar no grupo")
                    .font(.brand(15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Palette.accent.base, in: Capsule())
            }
            .buttonStyle(.pressable)

            Button("Agora não") { dismiss() }
                .font(.brand(13, weight: .semibold))
                .foregroundStyle(Playful.inkMuted)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Playful.canvas)
    }

    private var membersLine: String {
        let nomes = summary.others.map(\.name)
        switch nomes.count {
        case 0: return "Ainda sem ninguém"
        case 1: return "Com \(nomes[0])"
        case 2: return "Com \(nomes[0]) e \(nomes[1])"
        default: return "Com \(nomes[0]), \(nomes[1]) e mais \(nomes.count - 2)"
        }
    }
}
