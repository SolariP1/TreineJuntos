import SwiftUI

/// A foto da conversa: a pessoa, na privada; até três rostos, no grupo.
struct ConversationAvatar: View {
    let summary: ConversationSummary
    var size: CGFloat = 52

    var body: some View {
        if summary.isGroup {
            groupFaces
        } else if let pessoa = summary.others.first {
            PartnerFace(partner: pessoa, size: size)
        } else {
            Circle().fill(Playful.hairline).frame(width: size, height: size)
        }
    }

    private var groupFaces: some View {
        let rostos = Array(summary.others.prefix(3))
        let menor = size * 0.62
        return ZStack {
            Circle().fill(Palette.violet.soft).frame(width: size, height: size)
            if rostos.isEmpty {
                Image(systemName: "person.3.fill")
                    .font(.system(size: size * 0.32, weight: .semibold))
                    .foregroundStyle(Palette.violet.deep)
            } else {
                ForEach(Array(rostos.enumerated()), id: \.element.id) { index, pessoa in
                    PartnerFace(partner: pessoa, size: menor)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(groupOffset(index: index, count: rostos.count, size: size))
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func groupOffset(index: Int, count: Int, size: CGFloat) -> CGSize {
        guard count > 1 else { return .zero }
        let passo = size * 0.2
        return CGSize(
            width: (CGFloat(index) - CGFloat(count - 1) / 2) * passo,
            height: index.isMultiple(of: 2) ? -passo / 2 : passo / 2
        )
    }
}

/// O rosto de uma pessoa enquanto ela não tem foto: inicial sobre a cor do
/// esporte dela.
struct PartnerFace: View {
    let partner: WorkoutPartner
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(partner.sport.style.gradient)
            Text(partner.initials)
                .font(.display(size * 0.36))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(partner.name)
    }
}
