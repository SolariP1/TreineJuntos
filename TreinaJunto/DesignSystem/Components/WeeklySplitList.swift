import SwiftUI

/// A rotina semanal: um bloco por dia, com os exercícios em etiquetas.
/// Igual no Perfil e no Portfólio.
struct WeeklySplitList: View {
    let days: [WorkoutDay]
    var accent: ColorRamp = Palette.violet

    var body: some View {
        VStack(spacing: 8) {
            ForEach(days) { day in
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(day.day.prefix(3).uppercased())
                            .font(.mono(9.5, weight: .bold))
                            .foregroundStyle(accent.deep)
                            .padding(.horizontal, 7).padding(.vertical, 4)
                            .background(accent.soft, in: Capsule())
                        Text(day.focus)
                            .font(.brand(12.5, weight: .bold))
                            .foregroundStyle(Playful.ink)
                        Spacer()
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(day.exercises, id: \.self) { exercise in
                            Text(exercise)
                                .font(.brand(10, weight: .medium))
                                .foregroundStyle(Playful.inkMuted)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Playful.canvas, in: Capsule())
                        }
                    }
                }
                .padding(12)
                .background(
                    Playful.canvas.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
    }
}
