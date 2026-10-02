import SwiftUI

/// Escolher para qual conversa vai o convite do treino.
///
/// Abre ao tocar numa vaga livre. Lista as conversas privadas e os grupos —
/// o convite chega lá como mensagem, com Aceitar e Recusar.
struct InviteToWorkoutSheet: View {
    let targets: [ConversationSummary]
    var onPick: (ConversationSummary) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if targets.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 28))
                                .foregroundStyle(Playful.inkFaint)
                            Text("Você ainda não tem conversas.")
                                .font(.brand(14, weight: .semibold))
                                .foregroundStyle(Playful.ink)
                            Text("Curta alguém no Feed. Quando a curtida for mútua, dá pra convidar daqui.")
                                .font(.brand(12.5))
                                .foregroundStyle(Playful.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(targets) { resumo in
                            Button {
                                onPick(resumo)
                                dismiss()
                            } label: {
                                ConversationRow(summary: resumo)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(18)
            }
            .background(Playful.canvas)
            .navigationTitle("Convidar para o treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
