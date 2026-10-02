import SwiftUI

/// O treino que está de pé, no topo do Feed.
///
/// Muda de cara conforme o estado: aberto mostra as vagas e o botão de
/// começar; iniciado mostra o cronômetro e o botão de encerrar. É de onde a
/// Live Activity vai nascer.
struct ActiveWorkoutCard: View {
    let workout: Workout
    var onStart: () -> Void
    var onFinish: () -> Void
    var onLeave: () -> Void
    /// Tocar numa vaga livre. Só o anfitrião convida, e só antes de começar.
    var onInviteToSlot: () -> Void = {}
    /// Quem é cada participante, para mostrar o rosto na vaga.
    var partnerForID: (UUID) -> WorkoutPartner? = { _ in nil }

    private var style: SportStyle {
        workout.sport.style
    }

    /// O anfitrião cancela o treino; quem entrou por convite só sai dele.
    private var isHost: Bool {
        workout.hostID == SampleData.meID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            slots

            HStack(spacing: 8) {
                statusPill
                Spacer(minLength: 0)
                // Quem abriu o treino é quem começa e encerra; o convidado
                // acompanha.
                if isHost {
                    actionButton
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 20, y: 12)
    }

    // MARK: - Partes

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: style.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.22), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(.white)
                Text(workout.sport.label)
                    .font(.brand(12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            // Sair só existe antes de começar: depois de iniciado, o
            // caminho é encerrar, que registra quem apareceu.
            if workout.status == .open {
                Button(action: onLeave) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(isHost ? "Cancelar treino" : "Sair do treino")
            }
        }
    }

    /// Uma bolinha por vaga: o rosto de quem entrou, ou um + para chamar
    /// alguém (docs/PRODUTO.md §9.3).
    private var slots: some View {
        HStack(spacing: 8) {
            ForEach(workout.participants) { participante in
                face(for: participante.profileID)
                    .transition(.scale.combined(with: .opacity))
            }
            ForEach(0 ..< workout.freeSpots, id: \.self) { _ in
                emptySlot
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: workout.participants.count)
    }

    @ViewBuilder
    private func face(for profileID: UUID) -> some View {
        if profileID == SampleData.meID {
            Text("Eu")
                .font(.brand(12, weight: .bold))
                .foregroundStyle(style.deep)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
                .accessibilityLabel("Você")
        } else if let pessoa = partnerForID(profileID) {
            PartnerFace(partner: pessoa, size: 40)
                .overlay(Circle().stroke(.white, lineWidth: 2))
        } else {
            Image(systemName: "person.fill")
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.3), in: Circle())
        }
    }

    @ViewBuilder
    private var emptySlot: some View {
        let podeConvidar = isHost && workout.status == .open
        let circulo = Image(systemName: "plus")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white.opacity(podeConvidar ? 1 : 0.5))
            .frame(width: 40, height: 40)
            .background(
                Circle().strokeBorder(.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            )

        if podeConvidar {
            Button(action: onInviteToSlot) { circulo }
                .buttonStyle(.pressable)
                .accessibilityLabel("Convidar alguém para a vaga")
        } else {
            circulo.accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        if workout.status == .started, let inicio = workout.startedAt {
            HStack(spacing: 6) {
                Image(systemName: "stopwatch.fill").font(.system(size: 11))
                Text(inicio, style: .timer)
                    .font(.mono(13, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.white.opacity(0.22), in: Capsule())
        } else {
            Text(vagas)
                .font(.brand(12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white.opacity(0.18), in: Capsule())
        }
    }

    private var actionButton: some View {
        Button(action: workout.status == .open ? onStart : onFinish) {
            HStack(spacing: 6) {
                Image(systemName: workout.status == .open ? "play.fill" : "flag.checkered")
                    .font(.system(size: 11, weight: .bold))
                Text(workout.status == .open ? "Começar" : "Encerrar")
                    .font(.brand(13, weight: .bold))
            }
            .foregroundStyle(style.deep)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(.white, in: Capsule())
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Textos

    private var titulo: String {
        switch workout.status {
        case .started: "Treinando agora"
        case .open: workout.isParty ? "Party aberta" : "Treino aberto"
        default: workout.sport.label
        }
    }

    private var vagas: String {
        switch workout.freeSpots {
        case 0: "Cheio — \(workout.participants.count) confirmados"
        case 1: "Falta 1 pessoa"
        case let n: "Faltam \(n) pessoas"
        }
    }
}

/// Monta um treino já iniciado para o preview, fora do ViewBuilder.
private func startedSample() -> Workout? {
    guard var treino = try? Workout(hostID: SampleData.meID, sport: .musculacao) else { return nil }
    try? treino.start()
    return treino
}

#Preview("Aberto") {
    if let treino = try? Workout(hostID: SampleData.meID, sport: .corrida, maxParticipants: 4) {
        ActiveWorkoutCard(workout: treino, onStart: {}, onFinish: {}, onLeave: {})
            .padding()
    }
}

#Preview("Iniciado") {
    if let treino = startedSample() {
        ActiveWorkoutCard(workout: treino, onStart: {}, onFinish: {}, onLeave: {})
            .padding()
    }
}
