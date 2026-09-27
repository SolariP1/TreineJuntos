import SwiftUI

/// A foto em tela cheia, sobreposta à tela para o `matchedGeometryEffect`
/// poder animar a partir do avatar.
struct ProfilePhotoViewer: View {
    let profile: UserProfile
    let photoNamespace: Namespace.ID
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()
                .transition(.opacity)

            ProfileAvatar(profile: profile)
                .frame(width: 320, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .matchedGeometryEffect(id: "profilePhoto", in: photoNamespace, isSource: true)

            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                }
                Spacer()
            }
            .padding(20)
        }
        .onTapGesture(perform: onClose)
        .zIndex(10)
    }
}
