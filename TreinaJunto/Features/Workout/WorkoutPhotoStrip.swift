import SwiftUI
import UIKit

/// As fotos do treino em miniatura, com o botão de registrar outra.
struct WorkoutPhotoStrip: View {
    let photos: [WorkoutPhoto]
    let canAdd: Bool
    var onAdd: () -> Void
    /// Fundo claro (histórico) ou escuro (card colorido do Feed).
    var onColoredBackground = true
    var thumbSize: CGFloat = 44

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if canAdd {
                    Button(action: onAdd) {
                        VStack(spacing: 2) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Foto")
                                .font(.brand(9.5, weight: .bold))
                        }
                        .foregroundStyle(onColoredBackground ? .white : Palette.accent.deep)
                        .frame(width: thumbSize, height: thumbSize)
                        .background(
                            onColoredBackground ? AnyShapeStyle(.white.opacity(0.22)) :
                                AnyShapeStyle(Palette.accent.soft),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Registrar foto do treino")
                }

                ForEach(photos.reversed()) { foto in
                    WorkoutPhotoThumbnail(photo: foto, size: thumbSize)
                }
            }
        }
    }
}

/// Uma foto do treino, recortada em quadrado.
struct WorkoutPhotoThumbnail: View {
    let photo: WorkoutPhoto
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let imagem = UIImage(data: photo.imageData) {
                Image(uiImage: imagem)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.white.opacity(0.2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Foto do treino")
    }
}
