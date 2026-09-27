import SwiftUI

/// Lets the user broadcast that they're free to train right now, so they
/// show up to nearby people instead of only being able to invite others.
struct MarkAvailabilitySheet: View {
    var onPublish: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSport = "Corrida"
    @State private var selectedTime = "Agora"

    private let timeOptions = ["Agora", "Em 30 min", "Em 1h", "Mais tarde"]
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Que esporte?")
                            .font(.brand(13, weight: .bold))
                            .foregroundStyle(Theme.inkFaint)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(availableSports, id: \.self) { sport in
                                ChoiceChip(label: sport, isSelected: sport == selectedSport) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedSport = sport
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quando?")
                            .font(.brand(13, weight: .bold))
                            .foregroundStyle(Theme.inkFaint)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(timeOptions, id: \.self) { time in
                                ChoiceChip(label: time, isSelected: time == selectedTime) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedTime = time
                                    }
                                }
                            }
                        }
                    }

                    Text("Quem estiver perto de você vai ver que está disponível pra treinar \(selectedSport.lowercased()) — \(selectedTime.lowercased()).")
                        .font(.brand(12.5))
                        .foregroundStyle(Theme.inkMuted)

                    Button(action: {
                        onPublish(selectedSport, selectedTime)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                            Text("Publicar disponibilidade")
                        }
                        .font(.brand(15.5, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .foregroundStyle(.white)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .buttonStyle(.pressable)
                }
                .padding(20)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Marcar treino agora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
        .presentationDetents([.height(460)])
    }
}

private struct ChoiceChip: View {
    let label: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.brand(13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(isSelected ? .white : Theme.ink)
        .background(
            isSelected ? Theme.accent : Color.white,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? .clear : Theme.cardBorder, lineWidth: 1.2)
        )
        .buttonStyle(.pressable)
    }
}

#Preview {
    MarkAvailabilitySheet(onPublish: { _, _ in })
}
