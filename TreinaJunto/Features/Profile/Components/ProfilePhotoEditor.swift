import PhotosUI
import SwiftUI

/// A parte de fotos da edição de perfil: a foto principal e a tira de fotos
/// extras, com seleção e remoção.
///
/// Saiu do `EditProfileView` porque era metade do corpo dele — e porque
/// escolher foto é um assunto inteiro, com estados de carregamento próprios.
struct ProfilePhotoEditor: View {
    @Binding var photos: [Data]

    @State private var heroPickerItem: PhotosPickerItem?
    @State private var morePickerItems: [PhotosPickerItem] = []
    @State private var isLoadingHero = false
    @State private var isLoadingMore = false

    private let limite = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            heroPhoto
            thumbnailStrip
        }
    }

    private var heroPhoto: some View {
        PhotosPicker(selection: $heroPickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let hero = photos.first, let uiImage = UIImage(data: hero) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Theme.accent, Color(red: 0.788, green: 0.239, blue: 0.071)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.white.opacity(0.55))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                if isLoadingHero {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.black.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .overlay(ProgressView().tint(.white))
                }

                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(photos.isEmpty ? "Adicionar foto principal" : "Trocar foto")
                        .font(.brand(12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(14)
            }
        }
        .buttonStyle(.pressable)
        .shadow(color: Theme.accent.opacity(0.18), radius: 26, y: 14)
        .onChange(of: heroPickerItem) { _, newItem in
            guard let newItem else { return }
            isLoadingHero = true
            Task {
                let data = try? await newItem.loadTransferable(type: Data.self)
                await MainActor.run {
                    if let data {
                        if photos.isEmpty {
                            photos.append(data)
                        } else {
                            photos[0] = data
                        }
                    }
                    isLoadingHero = false
                    heroPickerItem = nil
                }
            }
        }
    }

    private var thumbnailStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FieldLabel("Mais fotos")
                Spacer()
                Text("\(photos.count)/\(limite)")
                    .font(.mono(10.5, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(photos.dropFirst().enumerated()), id: \.offset) { offset, data in
                        thumbnailTile(data: data, removeAt: offset + 1)
                    }

                    if photos.count < limite {
                        PhotosPicker(
                            selection: $morePickerItems,
                            maxSelectionCount: limite - photos.count,
                            matching: .images
                        ) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    Theme.cardBorder,
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                                )
                                .frame(width: 68, height: 88)
                                .overlay(
                                    Group {
                                        if isLoadingMore {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "plus")
                                                .font(.system(size: 15, weight: .semibold))
                                        }
                                    }
                                    .foregroundStyle(Theme.inkMuted)
                                )
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }
        }
        .onChange(of: morePickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            isLoadingMore = true
            Task {
                var newData: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newData.append(data)
                    }
                }
                await MainActor.run {
                    photos.append(contentsOf: newData)
                    if photos.count > limite {
                        photos = Array(photos.prefix(limite))
                    }
                    morePickerItems = []
                    isLoadingMore = false
                }
            }
        }
    }

    private func thumbnailTile(data: Data, removeAt index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else {
                    Rectangle().fill(Theme.accentSoft)
                }
            }
            .frame(width: 68, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                photos.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
    }
}
