import SwiftUI
import WoW2IosTheme

/// The card's surface recipe — a subset of the fe sdk's `SurfaceVariant`.
public enum CardVariant: String, Sendable, CaseIterable {
    /// The card fill with a hairline border.
    case outline
    /// The card fill lifted by the raised shadow, no border.
    case elevated
    /// The muted fill, no border — a quiet group inside a screen.
    case soft
}

/// Everything a card draws, resolved from the theme alone.
public struct CardAppearance: Sendable, Hashable {
    public var background: ColorToken
    public var foreground: ColorToken
    public var border: ColorToken?
    public var shadow: ShadowToken?
    public var radius: CGFloat
    public var padding: CGFloat

    public static func resolve(theme: Theme, variant: CardVariant) -> CardAppearance {
        let colors = theme.colors
        return switch variant {
        case .outline:
            CardAppearance(
                background: colors.card, foreground: colors.cardForeground, border: colors.border, shadow: nil,
                radius: theme.radii.lg, padding: theme.spacing.lg
            )
        case .elevated:
            CardAppearance(
                background: colors.card, foreground: colors.cardForeground, border: nil,
                shadow: theme.elevation.raised, radius: theme.radii.lg, padding: theme.spacing.lg
            )
        case .soft:
            CardAppearance(
                background: colors.muted, foreground: colors.foreground, border: nil, shadow: nil,
                radius: theme.radii.lg, padding: theme.spacing.lg
            )
        }
    }
}

/// A themed surface that groups related content — the fe sdk's `Card`.
public struct Card<Content: View>: View {
    private let variant: CardVariant
    private let padding: CGFloat?
    private let content: Content

    @Environment(\.wow2Theme) private var theme

    /// - Parameter padding: Overrides the theme's card padding; `0` for edge-to-edge media.
    public init(variant: CardVariant = .outline, padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.variant = variant
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        let look = CardAppearance.resolve(theme: theme, variant: variant)
        let shape = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        content
            .padding(padding ?? look.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(look.foreground.color)
            .background { shape.fill(look.background.color) }
            .overlay {
                if let border = look.border {
                    shape.strokeBorder(border.color, lineWidth: theme.sizes.hairline)
                }
            }
            .shadow(
                color: look.shadow?.color.color ?? .clear,
                radius: look.shadow?.radius ?? 0,
                x: 0,
                y: look.shadow?.y ?? 0
            )
    }
}
