import PhotosUI
import SwiftUI

struct EditProfileView: View {
    /// Entregue ao fechar com "Salvar". Quem grava é o ViewModel.
    var onSave: (UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile
    @FocusState private var focusedField: Field?

    private enum Field { case name, city, bio }
    private let bioLimit = 160

    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.onSave = onSave
        _draft = State(initialValue: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ProfilePhotoEditor(photos: $draft.photos)

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
                        FieldLabel("Esportes")
                        FlowLayout(spacing: 8) {
                            ForEach(Sport.allCases, id: \.self) { sport in
                                ToggleChip(label: sport.label, isOn: draft.sports.contains(sport)) {
                                    toggle(sport, in: &draft.sports)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FieldLabel("Interesses para treino")
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
                        onSave(draft)
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
                FieldLabel("Bio")
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

    private func toggle<T: Equatable>(_ value: T, in array: inout [T]) {
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
    EditProfileView(profile: SampleData.profile) { _ in }
}
