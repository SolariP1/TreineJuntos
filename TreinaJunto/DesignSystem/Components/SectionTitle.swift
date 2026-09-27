import SwiftUI

/// Título de seção dentro de um card. Estava duplicado como método privado
/// no Perfil e no Portfólio.
struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.display(14, weight: .semibold))
            .foregroundStyle(Playful.ink)
    }
}
