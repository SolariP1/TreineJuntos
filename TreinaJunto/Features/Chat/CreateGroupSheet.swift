import SwiftUI

/// Criar um grupo: nome e quem chamar das minhas conversas.
///
/// Quem não está nas minhas conversas entra depois, pelo link que o grupo
/// gera — essa tela não lista desconhecidos.
struct CreateGroupSheet: View {
    let contacts: [WorkoutPartner]
    var onCreate: (String, Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selected: Set<UUID> = []

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Nome do grupo")
                        TextField("Ex.: Corrida de sábado", text: $name)
                            .font(.brand(15))
                            .padding(14)
                            .background(
                                Playful.surface,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Chamar das suas conversas")
                        if contacts.isEmpty {
                            Text("Você ainda não tem conversas. Crie o grupo e chame gente pelo link.")
                                .font(.brand(12.5))
                                .foregroundStyle(Playful.inkMuted)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(contacts) { pessoa in
                                    contactRow(pessoa)
                                }
                            }
                        }
                    }

                    Label(
                        "Depois de criar, você pode gerar um link para chamar quem não está aqui.",
                        systemImage: "link"
                    )
                    .font(.brand(11.5))
                    .foregroundStyle(Playful.inkMuted)
                }
                .padding(18)
            }
            .background(Playful.canvas)
            .navigationTitle("Novo grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        onCreate(name, selected)
                        dismiss()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private func contactRow(_ pessoa: WorkoutPartner) -> some View {
        let marcado = selected.contains(pessoa.id)
        return Button {
            if marcado {
                selected.remove(pessoa.id)
            } else {
                selected.insert(pessoa.id)
            }
        } label: {
            HStack(spacing: 12) {
                PartnerFace(partner: pessoa, size: 40)
                Text(pessoa.name)
                    .font(.brand(14, weight: .semibold))
                    .foregroundStyle(Playful.ink)
                Spacer()
                Image(systemName: marcado ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(marcado ? Palette.accent.base : Playful.inkFaint)
            }
            .padding(10)
            .background(Playful.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(marcado ? .isSelected : [])
    }
}
