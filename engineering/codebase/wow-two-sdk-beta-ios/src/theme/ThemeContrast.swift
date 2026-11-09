import SwiftUI

/// WCAG contrast checks over a theme's colour pairs — the core of the fe sdk's `validateTheme`.
public enum ThemeContrast {
    /// Normal-size text.
    public static let text = 4.5
    /// Non-text affordances: field boundaries, focus rings.
    public static let ui = 3.0

    /// The WCAG contrast ratio of two opaque colours, `1...21`.
    public static func ratio(_ first: RGBA, _ second: RGBA) -> Double {
        let lighter = max(first.luminance, second.luminance)
        let darker = min(first.luminance, second.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// One pair a theme must satisfy.
    public struct Pair: Sendable, Hashable {
        public var name: String
        public var foreground: ColorToken
        public var background: ColorToken
        public var minimum: Double
    }

    /// The pairs every theme must clear in both modes: surface text, each tone's solid and soft text, and the
    /// field boundary and focus ring against the page.
    public static func pairs(_ colors: ThemeColors) -> [Pair] {
        var pairs: [Pair] = []
        let surfaces: [(String, ColorToken)] = [
            ("background", colors.background), ("card", colors.card), ("muted", colors.muted),
        ]
        for (name, surface) in surfaces {
            pairs.append(Pair(name: "foreground on \(name)", foreground: colors.foreground, background: surface, minimum: text))
            pairs.append(Pair(name: "mutedForeground on \(name)", foreground: colors.mutedForeground, background: surface, minimum: text))
        }
        pairs.append(Pair(name: "cardForeground on card", foreground: colors.cardForeground, background: colors.card, minimum: text))
        pairs.append(Pair(name: "inverseForeground on inverse", foreground: colors.inverseForeground, background: colors.inverse, minimum: text))
        pairs.append(Pair(name: "input on field", foreground: colors.input, background: colors.field, minimum: ui))
        pairs.append(Pair(name: "ring on background", foreground: colors.ring, background: colors.background, minimum: ui))
        for tone in Tone.allCases {
            let family = colors[tone]
            pairs.append(Pair(name: "\(tone).foreground on \(tone)", foreground: family.foreground, background: family.base, minimum: text))
            pairs.append(Pair(name: "\(tone).softForeground on \(tone).soft", foreground: family.softForeground, background: family.soft, minimum: text))
            pairs.append(Pair(name: "\(tone).softForeground on background", foreground: family.softForeground, background: colors.background, minimum: text))
        }
        return pairs
    }

    /// Every pair below its minimum, as `"<mode>: <pair> = <ratio> (need <minimum>)"`; empty when the theme passes.
    public static func failures(_ theme: Theme) -> [String] {
        var failures: [String] = []
        for scheme in [ColorScheme.light, .dark] {
            for pair in pairs(theme.colors) {
                let value = ratio(pair.foreground.resolve(scheme), pair.background.resolve(scheme))
                if value < pair.minimum {
                    failures.append(String(format: "%@: %@ = %.2f (need %.1f)", "\(scheme)", pair.name, value, pair.minimum))
                }
            }
        }
        return failures
    }
}
