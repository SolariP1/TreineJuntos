import SwiftUI

/// Botão redondo flutuante, usado na barra superior das telas sem navegação.
struct CircleIconButton: View {
    let symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Playful.ink)
                .frame(width: 44, height: 44)
                .background(Playful.surface, in: Circle())
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.pressable)
    }
}
