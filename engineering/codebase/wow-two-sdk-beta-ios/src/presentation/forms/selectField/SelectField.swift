import SwiftUI
import WoW2IosTheme

/// How a `SelectField` draws the selected option and its indicator, resolved from the theme alone.
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

        // Size the visible row in SwiftUI and layer its native menu on top. The menu can host its label
        // in a separate view graph, where trying multiple sizes of a compound label breaks rendering.
        SelectFieldLabel(title: title, description: description, systemImage: systemImage,
                         value: current?.title, appearance: look)
            .accessibilityHidden(true)
            .background(theme.colors.card.color)
            .overlay {
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
                    Color.clear
                        .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(SelectFieldPressStyle())
                .accessibilityLabel(title)
                .accessibilityValue(current?.title ?? Text(verbatim: ""))
                .accessibilityHint(description ?? Text(verbatim: ""))
            }
            .overlay(alignment: .leading) {
                // The row reports the common title offset independently of the native menu's view graph.
                let inset = theme.spacing.lg + (systemImage == nil ? 0 : theme.sizes.listRowLeading + theme.spacing.md)
                Color.clear
                    .frame(width: 0, height: 0)
                    .alignmentGuide(.leading) { _ in -inset }
                    .anchorPreference(key: RowTitleLeadingKey.self, value: .leading) { [$0] }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

private struct SelectFieldPressStyle: ButtonStyle {
    @Environment(\.wow2Theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? theme.colors.muted.color.opacity(0.4) : .clear)
    }
}

/// The visible row underlying the native selection menu.
struct SelectFieldLabel: View {
    let title: Text
    let description: Text?
    let systemImage: String?
    let value: Text?
    let appearance: SelectFieldAppearance

    @Environment(\.wow2Theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let systemImage {
                RowIconTile(systemImage: systemImage)
            }
            arrangement
        }
        .rowPadding(theme)
        .opacity(appearance.opacity)
    }

    @ViewBuilder
    private var arrangement: some View {
        if let value {
            if dynamicTypeSize.isAccessibilitySize {
                stacked(value: value)
            } else {
                ViewThatFits(in: .horizontal) {
                    inline(value: value)
                    stacked(value: value)
                }
            }
        } else {
            inline(value: nil)
        }
    }

    private func inline(value: Text?) -> some View {
        HStack(spacing: theme.spacing.md) {
            RowTitle(title: title, description: description)
                .fixedSize(horizontal: value != nil, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                styledValue(value)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            indicator
        }
    }

    private func stacked(value: Text) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            RowTitle(title: title, description: description)
            HStack(alignment: .lastTextBaseline, spacing: theme.spacing.md) {
                styledValue(value)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                indicator
            }
        }
    }

    private func styledValue(_ value: Text) -> some View {
        value
            .font(appearance.font.font)
            .foregroundStyle(appearance.value.color)
    }

    private var indicator: some View {
        Image(systemName: "chevron.up.chevron.down")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(appearance.indicator.color)
            .accessibilityHidden(true)
    }
}
