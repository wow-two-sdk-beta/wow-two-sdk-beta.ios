import SwiftUI
import WoW2IosTheme

/// An icon button bound to `isOn`, with an off symbol and an on symbol (`star` / `star.fill`) and a selected
/// fill — the fe sdk's `ToggleButton`. VoiceOver reads it as a toggle with its on/off value.
public struct ToggleIconButton: View {
    @Binding private var isOn: Bool
    private let label: Text
    private let systemImage: String
    private let selectedSystemImage: String
    private let variant: IconButtonVariant
    private let size: IconButtonSize
    private let selectedTone: Tone

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - systemImage: The off symbol.
    ///   - selectedSystemImage: The on symbol; `nil` keeps `systemImage` and shows the state by the fill alone.
    ///   - label: What VoiceOver reads; never shown.
    ///   - selectedTone: The on state's tone — `.warning` for a favourite star.
    public init(
        isOn: Binding<Bool>,
        systemImage: String,
        selectedSystemImage: String? = nil,
        label: LocalizedStringKey,
        variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        selectedTone: Tone = .primary
    ) {
        self.init(
            isOn: isOn, text: Text(label), systemImage: systemImage, selectedSystemImage: selectedSystemImage,
            variant: variant, size: size, selectedTone: selectedTone
        )
    }

    /// Takes `label` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        isOn: Binding<Bool>,
        systemImage: String,
        selectedSystemImage: String? = nil,
        label: Title,
        variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        selectedTone: Tone = .primary
    ) {
        self.init(
            isOn: isOn, text: Text(label), systemImage: systemImage, selectedSystemImage: selectedSystemImage,
            variant: variant, size: size, selectedTone: selectedTone
        )
    }

    private init(
        isOn: Binding<Bool>,
        text: Text,
        systemImage: String,
        selectedSystemImage: String?,
        variant: IconButtonVariant,
        size: IconButtonSize,
        selectedTone: Tone
    ) {
        self._isOn = isOn
        self.label = text
        self.systemImage = systemImage
        self.selectedSystemImage = selectedSystemImage ?? systemImage
        self.variant = variant
        self.size = size
        self.selectedTone = selectedTone
    }

    public var body: some View {
        Button {
            withAnimation(theme.motion.animation(.fast, reduceMotion: reduceMotion)) { isOn.toggle() }
        } label: {
            Label { label } icon: { Image(systemName: isOn ? selectedSystemImage : systemImage) }
        }
        .buttonStyle(IconButtonStyle(variant, size: size, isSelected: isOn, selectedTone: selectedTone))
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
