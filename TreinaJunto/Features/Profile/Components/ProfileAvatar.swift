import SwiftUI

/// A foto do perfil, ou a inicial sobre um gradiente quando não há foto.
struct ProfileAvatar: View {
    let profile: UserProfile

    var body: some View {
        if let first = profile.photos.first, let image = UIImage(data: first) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Theme.avatarGradients[1]
                Text(profile.initials)
                    .font(.display(34))
                    .foregroundStyle(.white)
            }
        }
    }
}
