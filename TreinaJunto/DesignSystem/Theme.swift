import SwiftUI

enum Theme {
    static let accent = Color(red: 0.910, green: 0.325, blue: 0.122)
    static let accentSoft = Color(red: 0.988, green: 0.890, blue: 0.827)
    static let ink = Color(red: 0.125, green: 0.102, blue: 0.075)
    static let inkMuted = Color(red: 0.431, green: 0.388, blue: 0.333)
    static let inkFaint = Color(red: 0.655, green: 0.604, blue: 0.522)
    static let screenBackground = Color(red: 0.953, green: 0.933, blue: 0.898)
    static let cardBorder = Color(red: 0.910, green: 0.875, blue: 0.820)
    static let success = Color(red: 0.247, green: 0.478, blue: 0.361)
    static let successSoft = Color(red: 0.863, green: 0.933, blue: 0.890)

    /// Personal accent gradients used for avatar placeholders.
    static let avatarGradients: [LinearGradient] = [
        LinearGradient(
            colors: [Color(red: 0.31, green: 0.49, blue: 0.97), Color(red: 0.17, green: 0.31, blue: 0.80)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.25, green: 0.68, blue: 0.45), Color(red: 0.12, green: 0.48, blue: 0.30)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.91, green: 0.37, blue: 0.66), Color(red: 0.72, green: 0.19, blue: 0.48)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.66, blue: 0.23), Color(red: 0.84, green: 0.48, blue: 0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ]
}

/// Tactile press feedback shared by primary buttons across the app —
/// a slight scale-down + darken on press, spring-released.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle {
        PressableButtonStyle()
    }
}

extension Font {
    /// Display face — Unbounded. Used for headlines and anything that needs
    /// the brand's geometric, characterful personality.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name = switch weight {
        case .black, .heavy: "Unbounded-ExtraBold"
        case .bold: "Unbounded-Bold"
        case .semibold: "Unbounded-SemiBold"
        case .medium: "Unbounded-Medium"
        default: "Unbounded-Regular"
        }
        return .custom(name, size: size)
    }

    /// Body/UI face — Plus Jakarta Sans. Used for everything else: labels,
    /// buttons, paragraph text.
    static func brand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = switch weight {
        case .bold, .black, .heavy: "PlusJakartaSans-Bold"
        case .semibold: "PlusJakartaSans-SemiBold"
        case .medium: "PlusJakartaSans-Medium"
        default: "PlusJakartaSans-Regular"
        }
        return .custom(name, size: size)
    }

    /// Data/mono face — JetBrains Mono. Used for stats, distances, numbers
    /// that benefit from tabular figures.
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(weight == .bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Medium", size: size)
    }
}
