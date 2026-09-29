import SwiftUI

/// A saudação do topo do Feed: avatar, nome, data e o sino com os convites
/// pendentes.
struct FeedGreeting: View {
    let inviteCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.avatarGradients[1])
                Text("L").font(.display(15)).foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Olá, Lucas 👋")
                    .font(.display(17, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Text(todayLabel)
                    .font(.brand(11.5, weight: .medium))
                    .foregroundStyle(Playful.inkMuted)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                    .frame(width: 42, height: 42)
                    .background(Playful.surface, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if inviteCount > 0 {
                            Text("\(inviteCount)")
                                .font(.brand(9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 17, height: 17)
                                .background(Palette.accent.base, in: Circle())
                                .overlay(Circle().stroke(Playful.canvas, lineWidth: 2))
                                .offset(x: 3, y: -3)
                        }
                    }
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .buttonStyle(.pressable)
        }
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        // Só a primeira letra — `.capitalized` daria "Terça-Feira, 22 De Setembro".
        let raw = formatter.string(from: Date())
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

#Preview {
    FeedGreeting(inviteCount: 3).padding()
}
