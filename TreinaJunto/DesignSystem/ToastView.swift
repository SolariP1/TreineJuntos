import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Palette.mint.base).frame(width: 7, height: 7)
            Text(message)
                .font(.brand(12.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Playful.ink, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
    }
}
