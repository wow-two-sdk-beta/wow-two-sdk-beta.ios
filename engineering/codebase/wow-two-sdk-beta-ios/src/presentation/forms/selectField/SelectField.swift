import SwiftUI
import WoW2IosTheme

/// What a `SelectField` row draws beside its label, resolved from the theme alone.
public struct SelectFieldAppearance: Sendable, Hashable {
    /// The current option's title.
    public var value: ColorToken
    /// The up-down chevron.
    public var indicator: ColorToken
    public var font: TypographyToken
    public var opacity: Double

    public static func resolve(theme: Theme, isEnabled: Bool = true) -> SelectFieldAppearance {
        SelectFieldAppearance(
            value: theme.colors.mutedForeground,
            indicator: theme.colors.subtleForeground,
            font: theme.typography.label,
            opacity: isEnabled ? 1 : theme.states.disabledOpacity
        )
    }
}

/// A row holding one setting chosen from a few options: icon, title, description and the current option, opening
/// a native menu of the options with a checkmark on the current one — the fe sdk's `Select` as a settings row.
/// Place it in a `ListGroup`.
public struct SelectField<Value: Hashable>: View {
    private let title: Text
    private let description: Text?
    private let systemImage: String?
    @Binding private var selection: Value
    private let options: [SelectOption<Value>]

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        selection: Binding<Value>,
        options: [SelectOption<Value>]
    ) {
        self.title = Text(title)
        self.description = description.map { Text($0) }
        self.systemImage = systemImage
        self._selection = selection
        self.options = options
    }

    /// Renders `title` and `description` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        description: String? = nil,
        systemImage: String? = nil,
        selection: Binding<Value>,
        options: [SelectOption<Value>]
    ) {
        self.title = Text(title)
        self.description = description.map { Text(verbatim: $0) }
        self.systemImage = systemImage
        self._selection = selection
        self.options = options
    }

    public var body: some View {
        let look = SelectFieldAppearance.resolve(theme: theme, isEnabled: isEnabled)
        let current = options.first { $0.value == selection }

        Menu {
            Picker(selection: $selection) {
                ForEach(options) { option in
                    if let systemImage = option.systemImage {
                        Label { option.title } icon: { Image(systemName: systemImage) }
                            .tag(option.value)
                    } else {
                        option.title.tag(option.value)
                    }
                }
            } label: {
                title
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: theme.spacing.md) {
                RowLabel(title: title, description: description, systemImage: systemImage)
                Spacer(minLength: theme.spacing.sm)
                if let current {
                    current.title
                        .font(look.font.font)
                        .foregroundStyle(look.value.color)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(look.indicator.color)
                    .accessibilityHidden(true)
            }
            .rowPadding(theme)
            .opacity(look.opacity)
        }
        .menuStyle(.button)
        .buttonStyle(RowPressStyle())
        .accessibilityLabel(title)
        .accessibilityValue(current?.title ?? Text(verbatim: ""))
        .accessibilityHint(description ?? Text(verbatim: ""))
    }
}
