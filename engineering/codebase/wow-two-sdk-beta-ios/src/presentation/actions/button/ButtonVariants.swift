import SwiftUI
import WoW2IosTheme

/// The button's visual recipe — the fe sdk's `Button` `variant` + `tone` collapsed to the four an app needs.
public enum ButtonVariant: String, Sendable, CaseIterable {
    /// The screen's main action: the solid primary tone.
    case primary
    /// A neutral, outlined action beside a primary one.
    case secondary
    /// An action that deletes or cannot be undone: the solid destructive tone.
    case destructive
    /// A text-only action: no fill, primary-coloured label.
    case ghost
}

/// The button height step, read from `Theme.sizes`.
public enum ButtonSize: String, Sendable, CaseIterable {
    case small, medium, large
}

/// Everything a themed button draws, resolved from the theme alone — the fe sdk's `Button.variants.ts`.
public struct ButtonAppearance: Sendable, Hashable {
    public var background: ColorToken?
    public var foreground: ColorToken
    public var border: ColorToken?
    public var height: CGFloat
    public var horizontalPadding: CGFloat
    public var radius: CGFloat
    public var font: TypographyToken
    public var opacity: Double

    public static func resolve(
        theme: Theme,
        variant: ButtonVariant,
        size: ButtonSize = .medium,
        isPressed: Bool = false,
        isEnabled: Bool = true
    ) -> ButtonAppearance {
        let colors = theme.colors
        var background: ColorToken?
        var foreground: ColorToken
        var border: ColorToken?
        var opacity = 1.0

        switch variant {
        case .primary:
            background = colors.primary.base
            foreground = colors.primary.foreground
            if isPressed { opacity = theme.states.pressedOpacity }
        case .destructive:
            background = colors.destructive.base
            foreground = colors.destructive.foreground
            if isPressed { opacity = theme.states.pressedOpacity }
        case .secondary:
            background = isPressed ? colors.muted : colors.card
            foreground = colors.foreground
            border = colors.border
        case .ghost:
            background = isPressed ? colors.primary.soft : nil
            foreground = colors.primary.softForeground
        }
        if !isEnabled { opacity = theme.states.disabledOpacity }

        var font = theme.typography.label
        font.weight = .semibold
        let height: CGFloat
        let padding: CGFloat
        switch size {
        case .small:
            height = theme.sizes.controlSmall
            padding = theme.spacing.md
            font.style = .footnote
        case .medium:
            height = theme.sizes.controlMedium
            padding = theme.spacing.lg
        case .large:
            height = theme.sizes.controlLarge
            padding = theme.spacing.xl
            font.style = .body
        }

        return ButtonAppearance(
            background: background,
            foreground: foreground,
            border: border,
            height: height,
            horizontalPadding: padding,
            radius: size == .large ? theme.radii.lg : theme.radii.md,
            font: font,
            opacity: opacity
        )
    }
}
