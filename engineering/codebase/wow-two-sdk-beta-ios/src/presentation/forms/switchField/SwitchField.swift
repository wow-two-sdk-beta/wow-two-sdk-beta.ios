import SwiftUI
import WoW2IosTheme

/// Styles any `Toggle` from the theme: the native switch tinted with the primary tone, the label in the theme's
/// label font — `.toggleStyle(.theme)`.
public struct ThemeToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        ThemeToggleBody(configuration: configuration)
    }
}

extension ToggleStyle where Self == ThemeToggleStyle {
    public static var theme: ThemeToggleStyle { ThemeToggleStyle() }
}

private struct ThemeToggleBody: View {
    let configuration: ToggleStyleConfiguration

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        Toggle(configuration)
            .toggleStyle(.switch)
            .tint(theme.colors.primary.base.color)
            .font(theme.typography.label.font)
            .foregroundStyle(theme.colors.foreground.color)
    }
}

/// A row holding one on/off setting: icon, title, description and the themed switch, read by VoiceOver as one
/// toggle — the fe sdk's `SwitchField`. Place it in a `ListGroup`.
public struct SwitchField: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let systemImage: String?
    @Binding private var isOn: Bool

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            RowLabel(title: title, description: description, systemImage: systemImage)
        }
        .toggleStyle(.theme)
        .rowPadding(theme)
        .background(theme.colors.card.color)
    }
}
