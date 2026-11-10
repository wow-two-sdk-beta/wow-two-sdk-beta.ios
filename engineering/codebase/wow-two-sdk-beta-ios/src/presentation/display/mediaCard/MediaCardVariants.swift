import SwiftUI
import WoW2IosTheme

/// Everything a media card draws, resolved from the theme alone — the fe sdk's `FeatureCard` recipe for an image
/// tile.
public struct MediaCardAppearance: Sendable, Hashable {
    /// The fill under the media slot, seen while an image loads or around one that does not fill the frame.
    public var mediaBackground: ColorToken
    /// The media frame's corner radius, drawn `.continuous`.
    public var mediaRadius: CGFloat
    public var title: ColorToken
    public var titleFont: TypographyToken
    public var caption: ColorToken
    public var captionFont: TypographyToken
    /// Lines the caption takes; the space is reserved, so cards in a row keep one height.
    public var captionLineLimit: Int
    /// The gap between the media and the title.
    public var spacing: CGFloat
    /// The gap between the title and the caption.
    public var textSpacing: CGFloat
    /// The accessory's distance from the media corner.
    public var accessoryInset: CGFloat
    /// The whole card's opacity: dimmed while pressed, more while disabled.
    public var opacity: Double

    public static func resolve(theme: Theme, isPressed: Bool = false, isEnabled: Bool = true) -> MediaCardAppearance {
        let colors = theme.colors
        var opacity = 1.0
        if isPressed { opacity = theme.states.pressedOpacity }
        if !isEnabled { opacity = theme.states.disabledOpacity }

        return MediaCardAppearance(
            mediaBackground: colors.muted,
            mediaRadius: theme.radii.xl,
            title: colors.foreground,
            titleFont: theme.typography.heading,
            caption: colors.mutedForeground,
            captionFont: theme.typography.caption,
            captionLineLimit: 2,
            spacing: theme.spacing(1.5),
            textSpacing: theme.spacing.xxs,
            accessoryInset: theme.spacing.sm,
            opacity: opacity
        )
    }
}

/// Draws a `MediaCard`'s content as a native `Button` or `NavigationLink`, dimming it while pressed:
/// `.buttonStyle(.mediaCard)`. `MediaCard` applies it itself; use it directly only around custom card content.
public struct MediaCardButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        MediaCardPressBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

extension ButtonStyle where Self == MediaCardButtonStyle {
    /// The media card's press treatment: `.buttonStyle(.mediaCard)`.
    public static var mediaCard: MediaCardButtonStyle { MediaCardButtonStyle() }
}

private struct MediaCardPressBody<Label: View>: View {
    let label: Label
    let isPressed: Bool

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = MediaCardAppearance.resolve(theme: theme, isPressed: isPressed, isEnabled: isEnabled)

        label
            .contentShape(Rectangle())
            .opacity(look.opacity)
            .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isPressed)
    }
}
