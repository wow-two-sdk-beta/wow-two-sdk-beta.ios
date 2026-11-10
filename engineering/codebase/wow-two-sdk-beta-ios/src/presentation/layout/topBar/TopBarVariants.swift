import SwiftUI
import WoW2IosTheme

/// Everything a top bar draws, resolved from the theme alone — the fe sdk's `StickyLayout` pinned to the top, with
/// no surface of its own.
public struct TopBarAppearance: Sendable, Hashable {
    public var title: ColorToken
    public var titleFont: TypographyToken
    public var subtitle: ColorToken
    public var subtitleFont: TypographyToken
    /// The gap between the title and the subtitle.
    public var titleSpacing: CGFloat
    /// The gap between a slot and the title, and between controls inside one slot.
    public var slotSpacing: CGFloat
    /// One control row: the 44 pt tap target.
    public var minHeight: CGFloat
    /// `0` when the container already pads its content.
    public var horizontalPadding: CGFloat

    /// - Parameter isInset: `false` drops the horizontal padding, for a container that already pads its content.
    public static func resolve(theme: Theme, isInset: Bool = true) -> TopBarAppearance {
        TopBarAppearance(
            title: theme.colors.foreground,
            titleFont: theme.typography.heading,
            subtitle: theme.colors.mutedForeground,
            subtitleFont: theme.typography.caption,
            titleSpacing: theme.spacing.xxs,
            slotSpacing: theme.spacing.sm,
            minHeight: theme.sizes.controlMedium,
            horizontalPadding: isInset ? theme.spacing.lg : 0
        )
    }
}
