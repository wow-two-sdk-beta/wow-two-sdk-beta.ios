import SwiftUI
import WoW2IosTheme

/// The spinner's colour — the fe sdk's `Spinner` tones, plus one that reads over media.
public enum SpinnerTone: String, Sendable, CaseIterable {
    /// The brand colour: `primary.base`.
    case primary
    /// The quiet default: `mutedForeground`.
    case neutral
    /// Over a camera picture or a photo: `scrimForeground` on a `scrim` backdrop.
    case overMedia
}

/// The spinner size, mapped onto the native control sizes.
public enum SpinnerSize: String, Sendable, CaseIterable {
    case small, medium, large
}

/// Everything a spinner draws, resolved from the theme alone — the fe sdk's `Spinner.variants.ts`.
public struct SpinnerAppearance: Sendable, Hashable {
    /// The indicator's tint.
    public var tint: ColorToken
    /// The label under the indicator.
    public var labelForeground: ColorToken
    public var labelFont: TypographyToken
    /// The backdrop behind indicator and label; `nil` draws none.
    public var background: ColorToken?
    public var padding: CGFloat
    public var radius: CGFloat
    /// The gap between indicator and label.
    public var spacing: CGFloat
    public var size: SpinnerSize

    public static func resolve(
        theme: Theme,
        tone: SpinnerTone = .neutral,
        size: SpinnerSize = .medium
    ) -> SpinnerAppearance {
        let colors = theme.colors
        let tint: ColorToken
        let label: ColorToken
        var background: ColorToken?
        switch tone {
        case .primary:
            tint = colors.primary.base
            label = colors.mutedForeground
        case .neutral:
            tint = colors.mutedForeground
            label = colors.mutedForeground
        case .overMedia:
            tint = colors.scrimForeground
            label = colors.scrimForeground
            background = colors.scrim
        }
        var font = theme.typography.caption
        if size == .large { font = theme.typography.label }

        return SpinnerAppearance(
            tint: tint,
            labelForeground: label,
            labelFont: font,
            background: background,
            padding: background == nil ? 0 : (size == .small ? theme.spacing.sm : theme.spacing.md),
            radius: theme.radii.lg,
            spacing: size == .small ? theme.spacing.xs : theme.spacing.sm,
            size: size
        )
    }
}
