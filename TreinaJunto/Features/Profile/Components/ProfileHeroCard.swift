import SwiftUI

/// O cartão colorido do topo do perfil: foto, nome, cidade e bio.
struct ProfileHeroCard: View {
    let profile: UserProfile
    let style: SportStyle
    let photoNamespace: Namespace.ID
    let isViewingPhoto: Bool
    var onTapAvatar: () -> Void

    var body: some View {
        ZStack {
            FloatingBlob(color: .white.opacity(0.18), size: 200, lobes: 6, speed: 11)
                .offset(x: -105, y: -45)
            FloatingBlob(color: .white.opacity(0.12), size: 150, lobes: 4, speed: 8)
                .offset(x: 115, y: 60)

            VStack(spacing: 13) {
                Button(action: onTapAvatar) {
                    ZStack {
                        BlobShape(phase: 0.9, lobes: 6, amplitude: 0.07)
                            .fill(.white.opacity(0.28))
                            .frame(width: 118, height: 118)

                        ProfileAvatar(profile: profile)
                            .frame(width: 98, height: 98)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 4))
                            .matchedGeometryEffect(
                                id: "profilePhoto",
                                in: photoNamespace,
                                isSource: !isViewingPhoto
                            )

                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(style.deep)
                            .frame(width: 28, height: 28)
                            .background(.white, in: Circle())
                            .offset(x: 36, y: 36)
                    }
                }
                .buttonStyle(.pressable)

                VStack(spacing: 6) {
                    Text(profile.name)
                        .font(.display(23, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.system(size: 10))
                        Text(profile.city).font(.brand(12, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.22), in: Capsule())

                    Text(profile.bio)
                        .font(.brand(12.5))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 26)
        }
        .frame(maxWidth: .infinity)
        .background(style.gradient, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: style.base.opacity(0.35), radius: 24, y: 14)
    }
}
