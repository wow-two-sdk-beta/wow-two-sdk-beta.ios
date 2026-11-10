import SwiftUI
import WoW2IosTheme

/// Everything a segmented control draws, resolved from the theme alone.
public struct SegmentedControlAppearance: Sendable, Hashable {
    public var track: ColorToken
    /// The sliding pill behind the selected segment.
    public var thumb: ColorToken
    public var thumbBorder: ColorToken
    public var thumbShadow: ShadowToken
    public var foreground: ColorToken
    public var selectedForeground: ColorToken
    public var font: TypographyToken
    public var height: CGFloat
    /// The gap between the track's edge and the thumb.
    public var inset: CGFloat
    public var radius: CGFloat
    public var opacity: Double

    public static func resolve(theme: Theme, isEnabled: Bool = true) -> SegmentedControlAppearance {
        var font = theme.typography.label
        font.weight = .semibold
        return SegmentedControlAppearance(
            track: theme.colors.muted,
            thumb: theme.colors.card,
            thumbBorder: theme.colors.borderStrong.opacity(0.5),
            thumbShadow: theme.elevation.raised,
            foreground: theme.colors.mutedForeground,
            selectedForeground: theme.colors.foreground,
            font: font,
            height: theme.sizes.controlMedium,
            inset: theme.spacing.xxs,
            radius: theme.radii.md,
            opacity: isEnabled ? 1 : theme.states.disabledOpacity
        )
    }
}

/// A row of mutually exclusive segments with a pill sliding to the chosen one — the fe sdk's `SegmentedPicker`,
/// themed. Each segment is a button VoiceOver reads with its position and the selected trait; the pill jumps under
/// Reduce Motion.
public struct SegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [SelectOption<Value>]

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var thumb

    public init(selection: Binding<Value>, options: [SelectOption<Value>]) {
        self._selection = selection
        self.options = options
    }

    public var body: some View {
        let look = SegmentedControlAppearance.resolve(theme: theme, isEnabled: isEnabled)
        let outer = RoundedRectangle(cornerRadius: look.radius, style: .continuous)
        let inner = RoundedRectangle(cornerRadius: max(look.radius - look.inset, 0), style: .continuous)

        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isSelected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    HStack(spacing: theme.spacing.xs) {
                        if let systemImage = option.systemImage {
                            Image(systemName: systemImage).accessibilityHidden(true)
                        }
                        option.title
                    }
                    .font(look.font.font)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle((isSelected ? look.selectedForeground : look.foreground).color)
                    .padding(.horizontal, theme.spacing.sm)
                    .frame(maxWidth: .infinity, minHeight: look.height - look.inset * 2)
                    .background {
                        if isSelected {
                            inner
                                .fill(look.thumb.color)
                                .overlay { inner.strokeBorder(look.thumbBorder.color, lineWidth: theme.sizes.hairline) }
                                .shadow(look.thumbShadow)
                                .matchedGeometryEffect(id: "thumb", in: thumb)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint(Text("\(index + 1) of \(options.count)"))
            }
        }
        .padding(look.inset)
        .frame(minHeight: look.height)
        .background { outer.fill(look.track.color) }
        .opacity(look.opacity)
        .animation(theme.motion.animation(.base, reduceMotion: reduceMotion), value: selection)
        .accessibilityElement(children: .contain)
    }
}
