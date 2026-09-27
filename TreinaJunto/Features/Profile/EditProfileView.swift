import PhotosUI
import SwiftUI

struct EditProfileView: View {
    @Binding var profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile
    @State private var heroPickerItem: PhotosPickerItem?
    @State private var morePickerItems: [PhotosPickerItem] = []
    @State private var isLoadingHero = false
    @State private var isLoadingMore = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, city, bio }
    private let bioLimit = 160

    init(profile: Binding<UserProfile>) {
        _profile = profile
        _draft = State(initialValue: profile.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    heroPhoto
                    thumbnailStrip

                    VStack(alignment: .leading, spacing: 18) {
                        underlineField(
                            "Nome",
                            text: $draft.name,
                            font: .display(21, weight: .semibold),
                            field: .name
                        )
                        underlineField(
                            "Cidade, UF",
                            text: $draft.city,
                            font: .brand(15, weight: .medium),
                            field: .city
                        )
                    }

                    bioEditor

                    VStack(alignment: .leading, spacing: 10) {
                        eyebrow("Esportes")
                        FlowLayout(spacing: 8) {
                            ForEach(availableSports, id: \.self) { sport in
                                ToggleChip(label: sport, isOn: draft.sports.contains(sport)) {
                                    toggle(sport, in: &draft.sports)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        eyebrow("Interesses para treino")
                        FlowLayout(spacing: 8) {
                            ForEach(availableInterests, id: \.self) { interest in
                                ToggleChip(
                                    label: interest,
                                    isOn: draft.trainingInterests.contains(interest)
                                ) {
                                    toggle(interest, in: &draft.trainingInterests)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.inkMuted)
                        .font(.brand(15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        profile = draft
                        dismiss()
                    }
                    .font(.brand(15, weight: .bold))
                    .foregroundStyle(Theme.accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Pronto") { focusedField = nil }
                        .font(.brand(14, weight: .semibold))
                }
            }
        }
    }

    // MARK: - Hero photo

    private var heroPhoto: some View {
        PhotosPicker(selection: $heroPickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let hero = draft.photos.first, let uiImage = UIImage(data: hero) {
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
                    Text(draft.photos.isEmpty ? "Adicionar foto principal" : "Trocar foto")
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
                        if draft.photos.isEmpty {
                            draft.photos.append(data)
                        } else {
                            draft.photos[0] = data
                        }
                    }
                    isLoadingHero = false
                    heroPickerItem = nil
                }
            }
        }
    }

    // MARK: - Thumbnail strip (extra photos)

    private var thumbnailStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                eyebrow("Mais fotos")
                Spacer()
                Text("\(draft.photos.count)/6")
                    .font(.mono(10.5, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(draft.photos.dropFirst().enumerated()), id: \.offset) { offset, data in
                        thumbnailTile(data: data, removeAt: offset + 1)
                    }

                    if draft.photos.count < 6 {
                        PhotosPicker(
                            selection: $morePickerItems,
                            maxSelectionCount: 6 - draft.photos.count,
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
                    draft.photos.append(contentsOf: newData)
                    if draft.photos.count > 6 {
                        draft.photos = Array(draft.photos.prefix(6))
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
                draft.photos.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Underline text field

    private func underlineField(
        _ placeholder: String,
        text: Binding<String>,
        font: Font,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(placeholder, text: text)
                .font(font)
                .foregroundStyle(Theme.ink)
                .focused($focusedField, equals: field)
            Rectangle()
                .fill(focusedField == field ? Theme.accent : Theme.cardBorder)
                .frame(height: focusedField == field ? 2 : 1)
                .animation(.easeOut(duration: 0.18), value: focusedField)
        }
    }

    // MARK: - Bio editor

    private var bioEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                eyebrow("Bio")
                Spacer()
                Text("\(draft.bio.count)/\(bioLimit)")
                    .font(.mono(10.5, weight: .medium))
                    .foregroundStyle(draft.bio.count > bioLimit ? Theme.accent : Theme.inkFaint)
            }
            TextEditor(text: $draft.bio)
                .font(.brand(14.5))
                .foregroundStyle(Theme.ink)
                .focused($focusedField, equals: .bio)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 84)
                .padding(.horizontal, -5)
                .onChange(of: draft.bio) { _, newValue in
                    if newValue.count > bioLimit {
                        draft.bio = String(newValue.prefix(bioLimit))
                    }
                }
            Rectangle()
                .fill(focusedField == .bio ? Theme.accent : Theme.cardBorder)
                .frame(height: focusedField == .bio ? 2 : 1)
                .animation(.easeOut(duration: 0.18), value: focusedField)
        }
    }

    // MARK: - Helpers

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.brand(10.5, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(Theme.inkFaint)
    }

    private func toggle(_ value: String, in array: inout [String]) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
        }
    }
}

private struct ToggleChip: View {
    let label: String
    let isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(label)
                    .font(.brand(12.5, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .foregroundStyle(isOn ? .white : Theme.inkMuted)
        .background(isOn ? Theme.accent : Color.white, in: Capsule())
        .overlay(Capsule().stroke(isOn ? .clear : Theme.cardBorder, lineWidth: 1.2))
        .buttonStyle(.pressable)
    }
}

#Preview {
    EditProfileView(profile: .constant(UserProfile()))
}
