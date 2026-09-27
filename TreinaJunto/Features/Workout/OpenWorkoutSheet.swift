import SwiftUI

/// Abrir um treino: escolher esporte, horário e com quanta gente.
///
/// Substitui a antiga folha de disponibilidade. A diferença não é de nome —
/// antes isso publicava um recado; agora cria um treino, que tem estado e
/// recebe convites.
struct OpenWorkoutSheet: View {
    let gym: String?
    let inviteBalance: GymInviteBalance
    var onOpen: (Sport, Int, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sport: Sport = .corrida
    @State private var time = "Agora"
    @State private var size = 2

    private let timeOptions = ["Agora", "Em 30 min", "Em 1h", "Mais tarde"]
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    /// Quantos visitantes cabem sem estourar o saldo de convites — só vale
    /// quando o treino é na academia da pessoa.
    private var sizeLimitFromInvites: Int? {
        guard gym != nil, inviteBalance.hasInvites else { return nil }
        return min(Workout.sizeRange.upperBound, inviteBalance.available() + 1)
    }

    private var maxSize: Int {
        sizeLimitFromInvites ?? Workout.sizeRange.upperBound
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    sportPicker
                    timePicker
                    sizePicker

                    Text(resumo)
                        .font(.brand(12.5))
                        .foregroundStyle(Theme.inkMuted)

                    if let aviso = avisoDeConvites {
                        InviteWarning(text: aviso)
                    }

                    openButton
                }
                .padding(20)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Abrir treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
        .presentationDetents([.height(620)])
    }

    // MARK: - Seções

    private var sportPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel("Que esporte?")
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Sport.allCases, id: \.self) { opcao in
                    ChoiceChip(label: opcao.label, isSelected: opcao == sport) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            sport = opcao
                        }
                    }
                }
            }
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel("Quando?")
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(timeOptions, id: \.self) { opcao in
                    ChoiceChip(label: opcao, isSelected: opcao == time) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            time = opcao
                        }
                    }
                }
            }
        }
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel("Com quanta gente?")

            HStack(spacing: 8) {
                ForEach(Workout.sizeRange, id: \.self) { opcao in
                    let cabe = opcao <= maxSize
                    ChoiceChip(
                        label: "\(opcao)",
                        isSelected: opcao == size,
                        isEnabled: cabe
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            size = opcao
                        }
                    }
                }
            }

            Text(size == 2 ? "Só vocês dois." : "Party de \(size) pessoas.")
                .font(.brand(11.5))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var openButton: some View {
        Button {
            onOpen(sport, size, time)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                Text("Abrir treino")
            }
            .font(.brand(15.5, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .foregroundStyle(.white)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .buttonStyle(.pressable)
    }

    // MARK: - Textos

    private var resumo: String {
        "Quem estiver perto de você vai ver que está disponível pra treinar "
            + "\(sport.label.lowercased()) — \(time.lowercased())."
    }

    /// O aviso que o documento pede: a pessoa precisa saber que a party gasta
    /// convite **aqui**, não no portão da academia.
    private var avisoDeConvites: String? {
        guard let gym, inviteBalance.hasInvites else { return nil }
        let disponiveis = inviteBalance.available()
        let visitantes = size - 1

        if visitantes == 0 {
            return nil
        }
        if disponiveis == 0 {
            return "Você não tem convites este mês, então não dá pra levar ninguém na \(gym)."
        }
        return "Levar \(visitantes) \(visitantes == 1 ? "pessoa" : "pessoas") na \(gym) "
            + "gasta \(visitantes) dos seus \(disponiveis) convites deste mês."
    }
}

private struct InviteWarning: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 12))
                .foregroundStyle(Palette.amber.deep)
            Text(text)
                .font(.brand(11.5, weight: .medium))
                .foregroundStyle(Palette.amber.deep)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.amber.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ChoiceChip: View {
    let label: String
    let isSelected: Bool
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.brand(13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(foreground)
        .background(
            isSelected ? Theme.accent : Color.white,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? .clear : Theme.cardBorder, lineWidth: 1.2)
        )
        .opacity(isEnabled ? 1 : 0.4)
        .disabled(!isEnabled)
        .buttonStyle(.pressable)
    }

    private var foreground: Color {
        isSelected ? .white : Theme.ink
    }
}

#Preview {
    OpenWorkoutSheet(
        gym: "Smart Fit",
        inviteBalance: GymInviteBalance(perMonth: 4, uses: [Date(), Date()])
    ) { _, _, _ in }
}
