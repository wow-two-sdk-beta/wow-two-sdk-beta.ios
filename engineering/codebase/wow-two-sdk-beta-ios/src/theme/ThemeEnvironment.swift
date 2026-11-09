import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.standard
}

extension EnvironmentValues {
    /// The theme SDK components read; `Theme.standard` until a view above sets one.
    public var wow2Theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// Applies `theme` to this view and everything below it, and tints native controls with its primary colour.
    ///
    /// Pass `tintsControls: false` when the asset catalogue's `AccentColor` already carries the brand: an explicit
    /// tint also colours toolbar glyphs on iOS 26, which the accent colour alone leaves in the label colour.
    public func wow2Theme(_ theme: Theme, tintsControls: Bool = true) -> some View {
        environment(\.wow2Theme, theme).tint(tintsControls ? theme.colors.primary.base.color : nil)
    }

    /// Paints the theme's page background edge to edge — the fe sdk's `body` default.
    public func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
}

private struct ThemedBackground: ViewModifier {
    @Environment(\.wow2Theme) private var theme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(theme.colors.foreground.color)
            .background(theme.colors.background.color.ignoresSafeArea())
    }
}
