import SwiftUI

/// O carrossel de fotos do perfil, com o botão de adicionar no fim.
struct ProfilePhotosCard: View {
    let photos: [Data]
    let style: SportStyle
    var onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Minhas fotos")
                Spacer()
                Button("Gerenciar", action: onManage)
                    .font(.brand(11.5, weight: .bold))
                    .foregroundStyle(style.deep)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    if photos.isEmpty {
                        ForEach(0 ..< 3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Playful.canvas)
                                .frame(width: 88, height: 112)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Playful.inkFaint)
                                )
                                .id("placeholder\(index)")
                        }
                    } else {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                            Group {
                                if let image = UIImage(data: data) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(Playful.canvas)
                                }
                            }
                            .frame(width: 88, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    Button(action: onManage) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                style.base.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                            )
                            .frame(width: 88, height: 112)
                            .overlay(
                                VStack(spacing: 5) {
                                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                                    Text("Adicionar").font(.brand(10, weight: .semibold))
                                }
                                .foregroundStyle(style.deep)
                            )
                    }
                    .buttonStyle(.pressable)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .playfulCard()
    }
}
