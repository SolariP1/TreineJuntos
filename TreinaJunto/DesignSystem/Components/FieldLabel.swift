import SwiftUI

/// A etiqueta miúda em maiúsculas acima de um campo de formulário.
struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.brand(10.5, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(Theme.inkFaint)
    }
}
