import SwiftUI
import WoW2IosTheme

/// Styles any SwiftUI `Button` from the theme: `.buttonStyle(.theme(.primary, isBusy: saving))`.
public struct ThemeButtonStyle: ButtonStyle {
    public var variant: ButtonVariant
    public var size: ButtonSize
    /// Shows a spinner over the transparent label, keeping the width, and ignores taps.
    public var isBusy: Bool
    /// Stretches the button to its container's width.
    public var isFullWidth: Bool

    public init(
        _ variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isBusy: Bool = false,
        isFullWidth: Bool = false
    ) {
        self.variant = variant
        self.size = size
        self.isBusy = isBusy
        self.isFullWidth = isFullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        ThemeButtonBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            variant: variant,
            size: size,
            isBusy: isBusy,
            isFullWidth: isFullWidth
        )
    }
}

extension ButtonStyle where Self == ThemeButtonStyle {
    /// The theme's button: `.buttonStyle(.theme(.secondary))`.
    public static func theme(
        _ variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isBusy: Bool = false,
        isFullWidth: Bool = false
    ) -> ThemeButtonStyle {
        ThemeButtonStyle(variant, size: size, isBusy: isBusy, isFullWidth: isFullWidth)
    }
}

private struct ThemeButtonBody<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let variant: ButtonVariant
    let size: ButtonSize
    let isBusy: Bool
    let isFullWidth: Bool

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = ButtonAppearance.resolve(
            theme: theme, variant: variant, size: size, isPressed: isPressed, isEnabled: isEnabled
        )
        let shape = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        label
            .font(look.font.font)
            .lineLimit(1)
            .opacity(isBusy ? 0 : 1)
            .overlay {
                if isBusy {
                    ProgressView().tint(look.foreground.color)
                }
            }
            .padding(.horizontal, look.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: look.height)
            .foregroundStyle(look.foreground.color)
            .background { shape.fill(look.background?.color ?? .clear) }
            .overlay {
                if let border = look.border {
                    shape.strokeBorder(border.color, lineWidth: theme.sizes.hairline)
                }
            }
            .contentShape(shape)
            .opacity(look.opacity)
            .allowsHitTesting(!isBusy)
            .accessibilityValue(isBusy ? Text("Loading") : Text(verbatim: ""))
            .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isPressed)
    }
}
