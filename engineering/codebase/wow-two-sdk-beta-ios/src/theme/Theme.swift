import SwiftUI

/// A complete visual theme: every token a component reads. Supply one with `.wow2Theme(_:)` and every SDK
/// component below it restyles; change one token and every component reading it follows.
public struct Theme: Sendable, Hashable, Identifiable {
    /// A stable name — the fe sdk's `theme-{id}`.
    public var id: String
    public var colors: ThemeColors
    public var typography: ThemeTypography
    public var spacing: ThemeSpacing
    public var radii: ThemeRadii
    public var sizes: ThemeSizes
    public var elevation: ThemeElevation
    public var motion: ThemeMotion

    public init(
        id: String,
        colors: ThemeColors = .standard,
        typography: ThemeTypography = .standard,
        spacing: ThemeSpacing = .standard,
        radii: ThemeRadii = .standard,
        sizes: ThemeSizes = .standard,
        elevation: ThemeElevation = .standard,
        motion: ThemeMotion = .standard
    ) {
        self.id = id
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.sizes = sizes
        self.elevation = elevation
        self.motion = motion
    }

    /// The fe sdk's default theme, token for token.
    public static let standard = Theme(id: "standard")

    /// This theme with `id` and the edits `change` makes — `Theme.standard.with(id: "acme") { $0.colors.primary = … }`.
    public func with(id: String, _ change: (inout Theme) -> Void) -> Theme {
        var copy = self
        copy.id = id
        change(&copy)
        return copy
    }
}
