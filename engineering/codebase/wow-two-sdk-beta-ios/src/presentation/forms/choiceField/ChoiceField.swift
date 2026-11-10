import SwiftUI
import WoW2IosTheme

/// What a `ChoiceField` row draws around its label, resolved from the theme alone.
public struct ChoiceFieldAppearance: Sendable, Hashable {
    /// The row fill: the card, `muted` while pressed.
    public var background: ColorToken
    /// The trailing checkmark, drawn only when selected; its slot is kept so titles never shift.
    public var checkmark: ColorToken
    public var showsCheckmark: Bool
    public var checkmarkFont: TypographyToken
    public var opacity: Double

    public static func resolve(
        theme: Theme,
        isSelected: Bool = false,
        isPressed: Bool = false,
        isEnabled: Bool = true
    ) -> ChoiceFieldAppearance {
        var checkmarkFont = theme.typography.label
        checkmarkFont.weight = .semibold
        return ChoiceFieldAppearance(
            background: isPressed ? theme.colors.muted : theme.colors.card,
            checkmark: theme.colors.primary.base,
            showsCheckmark: isSelected,
            checkmarkFont: checkmarkFont,
            opacity: isEnabled ? 1 : theme.states.disabledOpacity
        )
    }
}

/// A selectable list row, the radio of a list: an optional icon tile, a title, an optional subtitle and a trailing
/// checkmark when selected — the fe sdk's `Radio` as an iOS settings row. Place several in a `ListGroup`; VoiceOver
/// reads each as one button with the selected trait.
public struct ChoiceField: View {
    private let title: Text
    private let subtitle: Text?
    private let systemImage: String?
    private let isSelected: Bool
    private let action: @MainActor () -> Void

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(
            text: Text(title), subtitle: subtitle.map { Text($0) }, systemImage: systemImage, isSelected: isSelected,
            action: action
        )
    }

    /// Renders `title` and `subtitle` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        subtitle: String? = nil,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(
            text: Text(title), subtitle: subtitle.map { Text(verbatim: $0) }, systemImage: systemImage,
            isSelected: isSelected, action: action
        )
    }

    /// Selected while `selection` equals `value`; choosing the row sets it.
    public init<Value: Hashable>(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        value: Value,
        selection: Binding<Value>
    ) {
        self.init(
            title, subtitle: subtitle, systemImage: systemImage, isSelected: selection.wrappedValue == value,
            action: { selection.wrappedValue = value }
        )
    }

    /// Renders `title` and `subtitle` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol, Value: Hashable>(
        _ title: Title,
        subtitle: String? = nil,
        systemImage: String? = nil,
        value: Value,
        selection: Binding<Value>
    ) {
        self.init(
            title, subtitle: subtitle, systemImage: systemImage, isSelected: selection.wrappedValue == value,
            action: { selection.wrappedValue = value }
        )
    }

    private init(
        text: Text,
        subtitle: Text?,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = text
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                RowLabel(title: title, description: subtitle, systemImage: systemImage)
                    .layoutPriority(1)
                Spacer(minLength: theme.spacing.sm)
            }
        }
        .buttonStyle(ChoiceFieldStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ChoiceFieldStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        ChoiceFieldBody(label: configuration.label, isSelected: isSelected, isPressed: configuration.isPressed)
    }
}

private struct ChoiceFieldBody<Label: View>: View {
    let label: Label
    let isSelected: Bool
    let isPressed: Bool

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let look = ChoiceFieldAppearance.resolve(
            theme: theme, isSelected: isSelected, isPressed: isPressed, isEnabled: isEnabled
        )

        HStack(spacing: theme.spacing.md) {
            label
            Image(systemName: "checkmark")
                .font(look.checkmarkFont.font)
                .foregroundStyle(look.checkmark.color)
                .opacity(look.showsCheckmark ? 1 : 0)
                .accessibilityHidden(true)
        }
        .rowPadding(theme)
        .opacity(look.opacity)
        .contentShape(Rectangle())
        .background(look.background.color)
    }
}
