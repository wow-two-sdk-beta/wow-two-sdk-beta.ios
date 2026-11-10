import SwiftUI
import WoW2IosTheme

/// The icon button's fill treatment.
public enum IconButtonVariant: String, Sendable, CaseIterable {
    /// No fill; a `muted` fill while pressed. Toolbars and rows.
    case ghost
    /// The `muted` fill.
    case soft
    /// The solid primary tone.
    case filled
    /// The `scrim` fill with `scrimForeground` glyph — legible over a camera picture or a photo.
    case overMedia
}

/// The icon button's visual diameter; the hit target stays at least `sizes.controlMedium` (44 pt) at every size.
public enum IconButtonSize: String, Sendable, CaseIterable {
    case small, medium, large
}

/// Everything an icon button draws, resolved from the theme alone.
public struct IconButtonAppearance: Sendable, Hashable {
    public var background: ColorToken?
    public var foreground: ColorToken
    /// The visible circle's diameter.
    public var diameter: CGFloat
    /// The tappable square's side, never under 44 pt.
    public var hitTarget: CGFloat
    /// The glyph's text style; the symbol scales with Dynamic Type.
    public var font: TypographyToken
    public var opacity: Double

    /// - Parameters:
    ///   - isSelected: The on state of a `ToggleIconButton`.
    ///   - selectedTone: The tone the on state fills with.
    ///   - isDestructive: The button's role is `.destructive`.
    public static func resolve(
        theme: Theme,
        variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        isPressed: Bool = false,
        isEnabled: Bool = true,
        isSelected: Bool = false,
        selectedTone: Tone = .primary,
        isDestructive: Bool = false
    ) -> IconButtonAppearance {
        let colors = theme.colors
        var background: ColorToken?
        var foreground: ColorToken
        var opacity = 1.0
        let selected = colors[selectedTone]

        switch variant {
        case .ghost, .soft:
            if isSelected {
                background = selected.soft
                foreground = selected.softForeground
            } else {
                background = variant == .soft || isPressed ? colors.muted : nil
                foreground = isDestructive ? colors.destructive.softForeground : colors.foreground
            }
            if isPressed && (isSelected || variant == .soft) { opacity = theme.states.pressedOpacity }
        case .filled:
            let family = isDestructive && !isSelected ? colors.destructive : (isSelected ? selected : colors.primary)
            background = family.base
            foreground = family.foreground
            if isPressed { opacity = theme.states.pressedOpacity }
        case .overMedia:
            if isSelected {
                background = selected.base
                foreground = selected.foreground
            } else {
                background = colors.scrim
                foreground = colors.scrimForeground
            }
            if isPressed { opacity = theme.states.pressedOpacity }
        }
        if !isEnabled { opacity = theme.states.disabledOpacity }

        var font: TypographyToken
        let diameter: CGFloat
        switch size {
        case .small:
            font = theme.typography.label
            diameter = theme.sizes.controlSmall
        case .medium:
            font = theme.typography.heading
            diameter = theme.sizes.controlMedium
        case .large:
            font = theme.typography.title
            diameter = theme.sizes.controlLarge
        }
        font.weight = .semibold

        return IconButtonAppearance(
            background: background,
            foreground: foreground,
            diameter: diameter,
            hitTarget: max(diameter, theme.sizes.controlMedium),
            font: font,
            opacity: opacity
        )
    }
}
