import SwiftUI
import WoW2IosTheme

/// The field boundary for a state, resolved from the theme alone.
public struct FieldAppearance: Sendable, Hashable {
    public var background: ColorToken
    public var border: ColorToken
    public var borderWidth: CGFloat
    public var radius: CGFloat
    public var height: CGFloat

    public static func resolve(theme: Theme, isFocused: Bool = false, isInvalid: Bool = false) -> FieldAppearance {
        let border: ColorToken
        if isInvalid {
            border = theme.colors.destructive.base
        } else if isFocused {
            border = theme.colors.ring
        } else {
            border = theme.colors.input
        }
        return FieldAppearance(
            background: theme.colors.field,
            border: border,
            borderWidth: isFocused || isInvalid ? theme.sizes.ring : theme.sizes.hairline,
            radius: theme.radii.md,
            height: theme.sizes.controlMedium
        )
    }
}

extension View {
    /// Draws the theme's field chrome around a raw `TextField`, `SecureField` or `TextEditor`.
    public func fieldChrome(isFocused: Bool = false, isInvalid: Bool = false) -> some View {
        modifier(FieldChrome(isFocused: isFocused, isInvalid: isInvalid))
    }
}

private struct FieldChrome: ViewModifier {
    let isFocused: Bool
    let isInvalid: Bool

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let look = FieldAppearance.resolve(theme: theme, isFocused: isFocused, isInvalid: isInvalid)
        let shape = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        content
            .font(theme.typography.body.font)
            .foregroundStyle(theme.colors.foreground.color)
            .padding(.horizontal, theme.spacing.md)
            .frame(minHeight: look.height)
            .background { shape.fill(look.background.color) }
            .overlay { shape.strokeBorder(look.border.color, lineWidth: look.borderWidth) }
            .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isFocused)
    }
}

/// A labelled single-line text field with helper text and an error line — the fe sdk's `TextInput` inside its
/// `Field` chrome. `error` takes a server message as is, e.g. one of `ApiFailure.fieldErrors`.
public struct TextInput: View {
    private let label: Text
    @Binding private var text: String
    private let prompt: Text?
    private let message: Text?
    private let error: String?
    private let isSecure: Bool

    @FocusState private var isFocused: Bool
    @Environment(\.wow2Theme) private var theme

    public init(
        _ label: LocalizedStringKey,
        text: Binding<String>,
        prompt: LocalizedStringKey? = nil,
        message: LocalizedStringKey? = nil,
        error: String? = nil,
        isSecure: Bool = false
    ) {
        self.label = Text(label)
        self._text = text
        self.prompt = prompt.map { Text($0) }
        self.message = message.map { Text($0) }
        self.error = error
        self.isSecure = isSecure
    }

    /// Renders `label`, `prompt` and `message` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Label: StringProtocol>(
        _ label: Label,
        text: Binding<String>,
        prompt: String? = nil,
        message: String? = nil,
        error: String? = nil,
        isSecure: Bool = false
    ) {
        self.label = Text(label)
        self._text = text
        self.prompt = prompt.map { Text(verbatim: $0) }
        self.message = message.map { Text(verbatim: $0) }
        self.error = error
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            label
                .font(theme.typography.label.font)
                .foregroundStyle(theme.colors.foreground.color)
                .accessibilityHidden(true)

            field
                .focused($isFocused)
                .fieldChrome(isFocused: isFocused, isInvalid: error != nil)
                .accessibilityHint(error.map { Text($0) } ?? Text(verbatim: ""))

            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(theme.typography.caption.font)
                    .foregroundStyle(theme.colors.destructive.softForeground.color)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let message {
                message
                    .font(theme.typography.caption.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private var field: some View {
        let placeholder = prompt.map { $0.foregroundStyle(theme.colors.subtleForeground.color) }
        if isSecure {
            SecureField(text: $text, prompt: placeholder) { label }
        } else {
            TextField(text: $text, prompt: placeholder) { label }
        }
    }
}
