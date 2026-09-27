import SwiftUI

extension View {
    /// Staggered fade + rise shared by the playful screens.
    func sectionEntrance(_ appeared: Bool, index: Int) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.82).delay(Double(index) * 0.07),
                value: appeared
            )
    }
}
