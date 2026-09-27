import SwiftUI

struct InviteCardView: View {
    let invite: IncomingInvite
    var onAccept: () -> Void
    var onDecline: () -> Void

    private var style: SportStyle {
        invite.sport.style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                ZStack {
                    Circle().fill(style.gradient)
                    Text(invite.initials).font(.display(14)).foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(invite.name)
                        .font(.brand(13.5, weight: .bold))
                        .foregroundStyle(Playful.ink)
                    HStack(spacing: 4) {
                        Image(systemName: style.symbol).font(.system(size: 8, weight: .semibold))
                        Text(invite.sport.label).font(.brand(9.5, weight: .bold))
                    }
                    .foregroundStyle(style.deep)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.white.opacity(0.75), in: Capsule())
                }
                Spacer(minLength: 0)
            }

            Text(invite.when)
                .font(.brand(11, weight: .medium))
                .foregroundStyle(Playful.inkMuted)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(Playful.inkMuted)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .foregroundStyle(.white)
                .background(style.base, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .buttonStyle(.pressable)
            }
        }
        .padding(13)
        .frame(width: 196)
        .background(style.soft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: style.base.opacity(0.18), radius: 14, y: 8)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}
