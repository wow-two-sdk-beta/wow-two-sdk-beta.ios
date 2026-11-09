import SwiftUI
import WoW2IosTheme

/// A titled group of rows in one rounded surface, hairline separators between them — the fe sdk's `ListGroup`,
/// and the settings-style section of an iOS screen outside a `List`.
///
/// Rows paint the card fill themselves (`ListGroupItem`, `SwitchField` do); the separators are the border colour
/// showing through the hairline gaps between them.
public struct ListGroup<Content: View>: View {
    private let title: LocalizedStringKey?
    private let footer: LocalizedStringKey?
    private let content: Content

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)

        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let title {
                Text(title)
                    .font(theme.typography.eyebrow.font)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .padding(.horizontal, theme.spacing.md)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: theme.sizes.hairline) {
                content
            }
            .background(theme.colors.border.color)
            .clipShape(shape)
            .overlay { shape.strokeBorder(theme.colors.border.color, lineWidth: theme.sizes.hairline) }

            if let footer {
                Text(footer)
                    .font(theme.typography.caption.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, theme.spacing.md)
            }
        }
    }
}
