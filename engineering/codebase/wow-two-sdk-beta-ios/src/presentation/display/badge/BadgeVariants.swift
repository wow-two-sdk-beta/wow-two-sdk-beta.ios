import SwiftUI
import WoW2IosTheme

/// The badge's colour — the fe sdk's `Badge` tints, `brand` named `primary` as the theme names it.
public enum BadgeTone: String, Sendable, CaseIterable {
    case neutral, primary, success, warning, danger, info

    /// The theme tone family, `nil` for neutral.
    public var tone: Tone? {
        switch self {
        case .neutral: nil
        case .primary: .primary
        case .success: .success
        case .warning: .warning
        case .danger: .destructive
        case .info: .info
        }
    }
}

/// The badge's fill treatment.
public enum BadgeVariant: String, Sendable, CaseIterable {
    /// The tone's tinted fill — the default.
    case soft
    /// The tone's solid fill.
    case solid
    /// No fill, a border in the tone.
    case outline
}

/// The badge height step.
public enum BadgeSize: String, Sendable, CaseIterable {
    case small, medium
}

/// Everything a badge draws, resolved from the theme alone — the fe sdk's `Badge.variants.ts`.
public struct BadgeAppearance: Sendable, Hashable {
    public var background: ColorToken?
    public var foreground: ColorToken
    public var border: ColorToken?
    /// The status dot.
    public var dot: ColorToken
    public var dotSize: CGFloat
    public var height: CGFloat
    public var horizontalPadding: CGFloat
    public var spacing: CGFloat
    public var font: TypographyToken

    public static func resolve(
        theme: Theme,
        tone: BadgeTone = .neutral,
        variant: BadgeVariant = .soft,
        size: BadgeSize = .medium
    ) -> BadgeAppearance {
        let colors = theme.colors
        var background: ColorToken?
        let foreground: ColorToken
        var border: ColorToken?
        let dot: ColorToken

        if let family = tone.tone.map({ colors[$0] }) {
            switch variant {
            case .soft:
                background = family.soft
                foreground = family.softForeground
                dot = family.base
            case .solid:
                background = family.base
                foreground = family.foreground
                dot = family.foreground
            case .outline:
                foreground = family.softForeground
                border = family.base
                dot = family.base
            }
        } else {
            switch variant {
            case .soft:
                background = colors.muted
                foreground = colors.foreground
                dot = colors.mutedForeground
            case .solid:
                background = colors.inverse
                foreground = colors.inverseForeground
                dot = colors.inverseForeground
            case .outline:
                foreground = colors.foreground
                border = colors.borderStrong
                dot = colors.mutedForeground
            }
        }

        var font = theme.typography.caption
        font.weight = .medium
        if size == .small { font.style = .caption2 }

        return BadgeAppearance(
            background: background,
            foreground: foreground,
            border: border,
            dot: dot,
            dotSize: theme.spacing.sm * (size == .small ? 0.75 : 1),
            height: size == .small ? theme.spacing(5) : theme.spacing(6),
            horizontalPadding: size == .small ? theme.spacing.sm : theme.spacing(2.5),
            spacing: size == .small ? theme.spacing.xs : theme.spacing(1.5),
            font: font
        )
    }
}
