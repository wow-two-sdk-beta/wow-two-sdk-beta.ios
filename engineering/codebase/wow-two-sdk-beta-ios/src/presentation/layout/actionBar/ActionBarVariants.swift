import SwiftUI
import WoW2IosTheme

/// The bar's surface.
public enum ActionBarVariant: String, Sendable, CaseIterable {
    /// The page background — the bar reads as the screen's floor. The default.
    case page
    /// The card fill — the bar stands apart from a page-coloured scroll.
    case card
}

/// Everything an action bar draws, resolved from the theme alone — the fe sdk's `StickyLayout` pinned to the bottom.
public struct ActionBarAppearance: Sendable, Hashable {
    /// The fill, carried under the home indicator.
    public var background: ColorToken
    /// The top hairline that parts the bar from content scrolling under it.
    public var border: ColorToken
    public var borderWidth: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    /// The gap between the bar's controls.
    public var spacing: CGFloat

    public static func resolve(theme: Theme, variant: ActionBarVariant = .page) -> ActionBarAppearance {
        let colors = theme.colors
        return ActionBarAppearance(
            background: variant == .card ? colors.card : colors.background,
            border: colors.border,
            borderWidth: theme.sizes.hairline,
            horizontalPadding: theme.spacing.lg,
            verticalPadding: theme.spacing.md,
            spacing: theme.spacing(2.5)
        )
    }
}
