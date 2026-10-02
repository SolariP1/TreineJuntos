#if DEBUG
    import SwiftUI

    /// Botões para fingir o outro lado, no fim do Perfil. Só em Debug.
    struct DebugSimulatorCard: View {
        let simulator: DebugSimulator

        @Environment(\.openURL) private var openURL
        @State private var result: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Label("Simular o outro lado", systemImage: "ladybug.fill")
                    .font(.brand(13, weight: .bold))
                    .foregroundStyle(Playful.ink)
                Text("Só aparece em build Debug.")
                    .font(.brand(11))
                    .foregroundStyle(Playful.inkMuted)

                action("Quem eu curti me curte de volta", symbol: "heart.fill") {
                    await simulator.everyoneLikesBack()
                }
                action("Alguém aceita meu convite", symbol: "person.fill.checkmark") {
                    await simulator.someoneAcceptsMyInvite()
                }
                action("A última conversa responde", symbol: "bubble.left.fill") {
                    await simulator.latestConversationReplies()
                }
                action("Chega um link de grupo", symbol: "link") {
                    guard let url = await simulator.foreignGroupLink()
                    else { return "Falhou ao criar o grupo." }
                    openURL(url)
                    return nil
                }

                if let result {
                    Text(result)
                        .font(.brand(11.5, weight: .medium))
                        .foregroundStyle(Palette.violet.deep)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        Palette.violet.base.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }

        private func action(
            _ title: String,
            symbol: String,
            run: @escaping () async -> String?
        ) -> some View {
            Button {
                Task { result = await run() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 20)
                    Text(title).font(.brand(13, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(Palette.violet.deep)
                .padding(12)
                .background(Palette.violet.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.pressable)
        }
    }
#endif
