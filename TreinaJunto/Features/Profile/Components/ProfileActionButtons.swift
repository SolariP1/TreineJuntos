import SwiftUI

/// Os dois botões do fim do perfil: editar e sair.
struct ProfileActionButtons: View {
    let style: SportStyle
    var onEdit: () -> Void
    var onLogout: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil").font(.system(size: 13, weight: .semibold))
                    Text("Editar perfil").font(.brand(14.5, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .background(
                LinearGradient(colors: [style.base, style.deep], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: style.base.opacity(0.35), radius: 14, y: 8)
            .buttonStyle(.pressable)

            Button(action: onLogout) {
                Text("Sair")
                    .font(.brand(13.5, weight: .semibold))
                    .foregroundStyle(Playful.inkMuted)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .background(Playful.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .buttonStyle(.pressable)
        }
    }
}
