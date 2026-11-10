import SwiftUI
import WoW2IosTheme

/// Styles any SwiftUI `Button` (or `ShareLink`) whose label is a `Label` as an icon-only circle:
/// `Button("Close", systemImage: "xmark") {}.buttonStyle(.icon(.overMedia))`. The title stays the VoiceOver label.
public struct IconButtonStyle: ButtonStyle {
    public var variant: IconButtonVariant
    public var size: IconButtonSize
    /// Draws the on state — what `ToggleIconButton` passes.
    public var isSelected: Bool
    /// The tone the on state fills with.
    public var selectedTone: Tone

    public init(
        _ variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        isSelected: Bool = false,
        selectedTone: Tone = .primary
    ) {
        self.variant = variant
        self.size = size
        self.isSelected = isSelected
        self.selectedTone = selectedTone
    }

    public func makeBody(configuration: Configuration) -> some View {
        IconButtonBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            isDestructive: configuration.role == .destructive,
            style: self
        )
    }
}

extension ButtonStyle where Self == IconButtonStyle {
    /// The theme's icon-only button: `.buttonStyle(.icon(.soft, size: .small))`.
    public static func icon(
        _ variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        isSelected: Bool = false,
        selectedTone: Tone = .primary
    ) -> IconButtonStyle {
        IconButtonStyle(variant, size: size, isSelected: isSelected, selectedTone: selectedTone)
    }
}

private struct IconButtonBody<Content: View>: View {
    let label: Content
    let isPressed: Bool
    let isDestructive: Bool
    let style: IconButtonStyle

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = IconButtonAppearance.resolve(
            theme: theme,
            variant: style.variant,
            size: style.size,
            isPressed: isPressed,
            isEnabled: isEnabled,
            isSelected: style.isSelected,
            selectedTone: style.selectedTone,
            isDestructive: isDestructive
        )

        label
            .labelStyle(.iconOnly)
            .font(look.font.font)
            .foregroundStyle(look.foreground.color)
            .frame(width: look.diameter, height: look.diameter)
            .background { Circle().fill(look.background?.color ?? .clear) }
            .opacity(look.opacity)
            .frame(width: look.hitTarget, height: look.hitTarget)
            .contentShape(Rectangle())
            .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isPressed)
            .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: style.isSelected)
    }
}
