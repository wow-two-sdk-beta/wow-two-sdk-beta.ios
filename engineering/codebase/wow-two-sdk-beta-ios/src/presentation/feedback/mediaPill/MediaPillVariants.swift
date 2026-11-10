import SwiftUI
import WoW2IosTheme

/// The media pill's colour. `neutral` is the scrim; the others are the tone's solid fill, opaque so the state
/// reads over any picture.
public enum MediaPillTone: String, Sendable, CaseIterable {
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

/// The media pill's text step.
public enum MediaPillSize: String, Sendable, CaseIterable {
    /// A status line in a corner: `caption`, medium weight.
    case small
    /// A caption under controls: `label`, semibold.
    case medium
}

/// Everything a media pill draws, resolved from the theme alone — the fe sdk's `BadgeOverlay` look for media.
public struct MediaPillAppearance: Sendable, Hashable {
    public var background: ColorToken
    public var foreground: ColorToken
    public var font: TypographyToken
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    /// The gap between icon and title.
    public var spacing: CGFloat
    public var minHeight: CGFloat

    public static func resolve(
        theme: Theme,
        tone: MediaPillTone = .neutral,
        size: MediaPillSize = .medium
    ) -> MediaPillAppearance {
        let colors = theme.colors
        let background: ColorToken
        let foreground: ColorToken
        if let family = tone.tone.map({ colors[$0] }) {
            background = family.base
            foreground = family.foreground
        } else {
            background = colors.scrim
            foreground = colors.scrimForeground
        }

        var font: TypographyToken
        switch size {
        case .small:
            font = theme.typography.caption
            font.weight = .medium
        case .medium:
            font = theme.typography.label
            font.weight = .semibold
        }

        return MediaPillAppearance(
            background: background,
            foreground: foreground,
            font: font,
            horizontalPadding: size == .small ? theme.spacing.md : theme.spacing(3.5),
            verticalPadding: size == .small ? theme.spacing(1.5) : theme.spacing.sm,
            spacing: size == .small ? theme.spacing(1.5) : theme.spacing.sm,
            minHeight: size == .small ? theme.spacing(7) : theme.sizes.controlSmall
        )
    }
}
