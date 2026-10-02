import SwiftUI

/// Uma linha da lista do Chat.
struct ConversationRow: View {
    let summary: ConversationSummary

    var body: some View {
        HStack(spacing: 12) {
            ConversationAvatar(summary: summary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(summary.title)
                        .font(.brand(14.5, weight: .bold))
                        .foregroundStyle(Playful.ink)
                        .lineLimit(1)
                    if summary.isGroup {
                        Text("\(summary.others.count + 1)")
                            .font(.brand(10, weight: .bold))
                            .foregroundStyle(Palette.violet.deep)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Palette.violet.soft, in: Capsule())
                            .accessibilityLabel("\(summary.others.count + 1) pessoas")
                    }
                    Spacer(minLength: 0)
                    if let quando = summary.lastMessage?.createdAt {
                        // pt_BR fixo, como o resto do app. Formatado antes
                        // de virar Text: o Text com `format:` troca o idioma
                        // pelo do aparelho, e um iPhone em inglês mostrava
                        // "2 hr ago".
                        Text(
                            quando.formatted(
                                .relative(presentation: .numeric, unitsStyle: .abbreviated)
                                    .locale(Locale(identifier: "pt_BR"))
                            )
                        )
                        .font(.brand(10.5, weight: .medium))
                        .foregroundStyle(Playful.inkFaint)
                    }
                }

                Text(preview)
                    .font(.brand(12.5))
                    .foregroundStyle(Playful.inkMuted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Playful.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    private var preview: String {
        guard let mensagem = summary.lastMessage else {
            return summary.isGroup ? "Grupo criado. Diga oi!" : "Vocês se curtiram. Diga oi!"
        }
        let autor = mensagem.authorID == SampleData.meID ? "Você: " : ""
        switch mensagem.content {
        case let .text(texto):
            return autor + texto
        case .workoutInvite:
            return autor + "Convite para treinar"
        }
    }
}
