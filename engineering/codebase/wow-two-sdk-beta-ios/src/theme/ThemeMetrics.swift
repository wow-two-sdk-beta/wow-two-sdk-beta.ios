import SwiftUI

/// The spacing density — the fe sdk's `--spacing` presets (0.21875 · 0.25 · 0.28125 rem).
public enum ThemeDensity: String, Sendable, CaseIterable {
    case compact, comfortable, spacious

    /// The base unit in points.
    public var unit: CGFloat {
        switch self {
        case .compact: 3.5
        case .comfortable: 4
        case .spacious: 4.5
        }
    }
}

/// The spacing scale, every step a multiple of one unit so a density change moves the whole layout.
public struct ThemeSpacing: Sendable, Hashable {
    public var unit: CGFloat

    public init(unit: CGFloat = ThemeDensity.comfortable.unit) {
        self.unit = unit
    }

    public init(density: ThemeDensity) {
        self.init(unit: density.unit)
    }

    /// `n` units — the fe sdk's Tailwind step (`p-4` → `spacing(4)`).
    public func callAsFunction(_ steps: CGFloat) -> CGFloat { unit * steps }

    public var xxs: CGFloat { unit * 0.5 }
    public var xs: CGFloat { unit }
    public var sm: CGFloat { unit * 2 }
    public var md: CGFloat { unit * 3 }
    public var lg: CGFloat { unit * 4 }
    public var xl: CGFloat { unit * 6 }
    public var xxl: CGFloat { unit * 8 }

    public static let standard = ThemeSpacing()
}

/// The corner radii — the fe sdk's `--radius-{md,lg,xl,2xl}` plus `sm`. Components draw them `.continuous`.
public struct ThemeRadii: Sendable, Hashable {
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var xxl: CGFloat

    public init(sm: CGFloat = 4, md: CGFloat = 8, lg: CGFloat = 12, xl: CGFloat = 16, xxl: CGFloat = 24) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }

    /// Every radius × `factor` — `0` for a square theme, `1.5` for a softer one.
    public func scaled(_ factor: CGFloat) -> ThemeRadii {
        ThemeRadii(sm: sm * factor, md: md * factor, lg: lg * factor, xl: xl * factor, xxl: xxl * factor)
    }

    public static let standard = ThemeRadii()
}

/// Control heights and stroke widths. `medium` keeps Apple's 44 pt minimum tap target.
public struct ThemeSizes: Sendable, Hashable {
    public var controlSmall: CGFloat
    public var controlMedium: CGFloat
    public var controlLarge: CGFloat
    /// Borders and separators.
    public var hairline: CGFloat
    /// The focus ring.
    public var ring: CGFloat

    public init(
        controlSmall: CGFloat = 32,
        controlMedium: CGFloat = 44,
        controlLarge: CGFloat = 52,
        hairline: CGFloat = 1,
        ring: CGFloat = 2
    ) {
        self.controlSmall = controlSmall
        self.controlMedium = controlMedium
        self.controlLarge = controlLarge
        self.hairline = hairline
        self.ring = ring
    }

    public static let standard = ThemeSizes()
}

/// One drop shadow.
public struct ShadowToken: Sendable, Hashable {
    public var color: ColorToken
    public var radius: CGFloat
    public var y: CGFloat

    public init(color: ColorToken, radius: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.y = y
    }
}

/// The elevation scale: raised cards and floating overlays.
public struct ThemeElevation: Sendable, Hashable {
    public var raised: ShadowToken
    public var overlay: ShadowToken

    public init(raised: ShadowToken, overlay: ShadowToken) {
        self.raised = raised
        self.overlay = overlay
    }

    public static let standard = ThemeElevation(
        raised: ShadowToken(color: ColorToken("#0000001a", "#00000066"), radius: 6, y: 2),
        overlay: ShadowToken(color: ColorToken("#00000026", "#00000080"), radius: 16, y: 6)
    )
}

extension View {
    /// Draws `shadow`, resolved for the current colour scheme.
    public func shadow(_ shadow: ShadowToken) -> some View {
        self.shadow(color: shadow.color.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
