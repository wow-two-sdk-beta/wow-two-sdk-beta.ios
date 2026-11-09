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
    public func wow2Theme(_ theme: Theme) -> some View {
        environment(\.wow2Theme, theme).tint(theme.colors.primary.base.color)
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
