import SwiftUI

/// Um balão de mensagem.
struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool
    /// Nome de quem escreveu, só no grupo e só nas mensagens dos outros.
    var authorName: String?
    /// O treino do convite, quando a mensagem é um convite.
    var workoutCard: ConversationViewModel.WorkoutCard?
    var onRespond: (Bool) -> Void = { _ in }

    var body: some View {
        HStack {
            if isMine {
                Spacer(minLength: 48)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                if let authorName, !isMine {
                    Text(authorName)
                        .font(.brand(10.5, weight: .bold))
                        .foregroundStyle(Palette.violet.deep)
                        .padding(.leading, 6)
                }
                content
            }

            if !isMine {
                Spacer(minLength: 48)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.content {
        case let .text(texto):
            Text(texto)
                .font(.brand(14))
                .foregroundStyle(isMine ? .white : Playful.ink)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(
                    isMine ? Palette.accent.base : Playful.surface,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

        case .workoutInvite:
            if let workoutCard {
                WorkoutInviteMessageCard(
                    workout: workoutCard.workout,
                    state: workoutCard.state,
                    onRespond: onRespond
                )
            } else {
                // O treino sumiu (ou ainda está carregando): melhor um aviso
                // simples do que um card quebrado.
                Label("Convite para treinar", systemImage: "figure.run")
                    .font(.brand(13, weight: .semibold))
                    .foregroundStyle(Palette.violet.deep)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        Palette.violet.soft,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        }
    }
}
