import SwiftUI
import WoW2IosTheme

/// Where an option tile shows its title.
public enum OptionTileTitlePosition: String, Sendable, CaseIterable {
    /// Under the art — the default.
    case below
    /// Over the art.
    case above
    /// Not drawn; VoiceOver still reads it as the tile's label — for art that speaks for itself.
    case hidden
}

/// Everything an option tile draws, resolved from the theme alone — the fe sdk's `OptionTile.variants.ts`.
public struct OptionTileAppearance: Sendable, Hashable {
    /// The art's outline: a hairline when unselected, the selection ring when selected.
    public var border: ColorToken
    public var borderWidth: CGFloat
    /// The wash over the art while pressed.
    public var pressedWash: ColorToken?
    /// The non-colour selection cue: a checkmark badge on the art's top-trailing corner.
    public var showsCheckmark: Bool
    public var checkmarkBackground: ColorToken
    public var checkmarkForeground: ColorToken
    /// The ring that lifts the badge off the art.
    public var checkmarkBorder: ColorToken
    public var checkmarkSize: CGFloat
    public var checkmarkInset: CGFloat
    public var checkmarkFont: TypographyToken
    public var title: ColorToken
    public var titleFont: TypographyToken
    /// The gap between the art and the title.
    public var spacing: CGFloat
    public var radius: CGFloat
    /// The smallest art side, so a tile stays a 44 pt target.
    public var minimumSide: CGFloat
    public var scale: CGFloat
    public var opacity: Double

    public static func resolve(
        theme: Theme,
        isSelected: Bool = false,
        isPressed: Bool = false,
        isEnabled: Bool = true
    ) -> OptionTileAppearance {
        let colors = theme.colors
        var titleFont = theme.typography.caption
        titleFont.weight = isSelected ? .semibold : .medium
        var checkmarkFont = theme.typography.eyebrow
        checkmarkFont.weight = .bold

        return OptionTileAppearance(
            border: isSelected ? colors.primary.base : colors.border,
            borderWidth: isSelected ? theme.sizes.ring : theme.sizes.hairline,
            pressedWash: isPressed ? colors.primary.base.opacity(theme.states.pressedWashOpacity) : nil,
            showsCheckmark: isSelected,
            checkmarkBackground: colors.primary.base,
            checkmarkForeground: colors.primary.foreground,
            checkmarkBorder: colors.background,
            checkmarkSize: theme.spacing(6),
            checkmarkInset: theme.spacing.xs,
            checkmarkFont: checkmarkFont,
            title: isSelected ? colors.foreground : colors.mutedForeground,
            titleFont: titleFont,
            spacing: theme.spacing.sm,
            radius: theme.radii.lg,
            minimumSide: theme.sizes.controlMedium,
            scale: isPressed ? theme.states.pressedScale : 1,
            opacity: isEnabled ? 1 : theme.states.disabledOpacity
        )
    }
}

/// The strip's layout, resolved from the theme alone — the fe sdk's `OptionTileGroup.variants.ts`.
public struct OptionTileStripAppearance: Sendable, Hashable {
    /// The gap between tiles.
    public var spacing: CGFloat
    /// Room above and below the tiles for the ring and the pressed scale.
    public var verticalPadding: CGFloat

    public static func resolve(theme: Theme) -> OptionTileStripAppearance {
        OptionTileStripAppearance(spacing: theme.spacing.md, verticalPadding: theme.sizes.ring)
    }
}
