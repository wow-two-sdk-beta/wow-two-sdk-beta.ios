import SwiftUI
import UIKit

/// One sRGB colour with alpha, each channel in `0...1`.
public struct RGBA: Sendable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Reads `#rrggbb` or `#rrggbbaa`; the `#` is optional. An unreadable string traps in debug and yields magenta.
    public init(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else {
            assertionFailure("RGBA(hex:) cannot read \(hex)")
            self.init(red: 1, green: 0, blue: 1)
            return
        }
        let hasAlpha = digits.count == 8
        let shift: UInt64 = hasAlpha ? 8 : 0
        self.init(
            red: Double((value >> (16 + shift)) & 0xFF) / 255,
            green: Double((value >> (8 + shift)) & 0xFF) / 255,
            blue: Double((value >> shift) & 0xFF) / 255,
            alpha: hasAlpha ? Double(value & 0xFF) / 255 : 1
        )
    }

    /// The `#rrggbb` form, alpha dropped.
    public var hex: String {
        func byte(_ channel: Double) -> Int { Int((min(max(channel, 0), 1) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", byte(red), byte(green), byte(blue))
    }

    /// The same colour at `alpha`.
    public func opacity(_ alpha: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// This colour drawn over the opaque `backdrop` — what the eye sees of a translucent fill.
    public func composited(over backdrop: RGBA) -> RGBA {
        func blend(_ top: Double, _ bottom: Double) -> Double { top * alpha + bottom * (1 - alpha) }
        return RGBA(red: blend(red, backdrop.red), green: blend(green, backdrop.green), blue: blend(blue, backdrop.blue))
    }

    /// WCAG relative luminance.
    public var luminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}

/// A semantic colour token: one value for light mode and one for dark, resolved by the view's colour scheme.
public struct ColorToken: Sendable, Hashable {
    public var light: RGBA
    public var dark: RGBA

    public init(light: RGBA, dark: RGBA) {
        self.light = light
        self.dark = dark
    }

    /// A token from two hex strings — the form the fe sdk's `index.css` declares its tokens in.
    public init(_ light: String, _ dark: String) {
        self.init(light: RGBA(hex: light), dark: RGBA(hex: dark))
    }

    /// A token that keeps one value in both modes.
    public init(_ both: String) {
        self.init(both, both)
    }

    /// The value for `scheme`.
    public func resolve(_ scheme: ColorScheme) -> RGBA {
        scheme == .dark ? dark : light
    }

    /// The same token at `alpha` in both modes.
    public func opacity(_ alpha: Double) -> ColorToken {
        ColorToken(light: light.opacity(alpha), dark: dark.opacity(alpha))
    }

    /// A dynamic SwiftUI colour that follows the environment's colour scheme, `.preferredColorScheme` included.
    public var color: Color {
        let light = light.uiColor
        let dark = dark.uiColor
        return Color(uiColor: UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }
}

extension ShapeStyle where Self == Color {
    /// The token's dynamic colour, for `foregroundStyle(.token(theme.colors.foreground))`.
    public static func token(_ token: ColorToken) -> Color { token.color }
}
