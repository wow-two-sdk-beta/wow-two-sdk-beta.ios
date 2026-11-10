import SwiftUI
import WoW2IosTheme

/// What leads each item of a `BulletList`.
public enum BulletListMarker: Sendable, Hashable {
    /// A small filled circle — the default.
    case dot
    /// An SF Symbol, drawn at the text's size on its baseline (`"checkmark"`, `"xmark"`).
    case symbol(String)
    /// `1.`, `2.`, … right-aligned in one column, so wrapped lines align across items.
    case number
}

/// The marker's colour, named as `Badge` names its tones.
public enum BulletListTone: String, Sendable, CaseIterable {
    case neutral, primary, success, warning, danger, info

    /// The theme tone family, `nil` for neutral.
    public var tone: Tone? {
        switch self {
        case .neutral: nil
        case .primary: .primary
        case .success: .success
        case .warning: .warning
        case .danger: .destructive
        case .info: .info
        }
    }
}

/// Everything a bullet list draws, resolved from the theme alone — the fe sdk's `DescriptionList` spacing and
/// type for a plain list.
public struct BulletListAppearance: Sendable, Hashable {
    /// The marker colour: the tone's `base` for a dot, its `softForeground` for a symbol or number (text contrast).
    public var marker: ColorToken
    public var text: ColorToken
    public var font: TypographyToken
    /// The number marker's font: the text role, medium weight.
    public var markerFont: TypographyToken
    /// The dot's diameter.
    public var dotSize: CGFloat
    /// The gap between the marker and the text.
    public var markerSpacing: CGFloat
    /// The gap between items.
    public var itemSpacing: CGFloat

    public static func resolve(
        theme: Theme,
        marker: BulletListMarker = .dot,
        tone: BulletListTone = .primary
    ) -> BulletListAppearance {
        let colors = theme.colors
        let markerColor: ColorToken
        if let family = tone.tone.map({ colors[$0] }) {
            markerColor = marker == .dot ? family.base : family.softForeground
        } else {
            markerColor = colors.mutedForeground
        }

        var markerFont = theme.typography.body
        markerFont.weight = .medium

        return BulletListAppearance(
            marker: markerColor,
            text: colors.foreground,
            font: theme.typography.body,
            markerFont: markerFont,
            dotSize: theme.spacing(1.5),
            markerSpacing: theme.spacing(2.5),
            itemSpacing: theme.spacing.sm
        )
    }
}
