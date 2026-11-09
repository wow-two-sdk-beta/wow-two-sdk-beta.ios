import SwiftUI
import WoW2IosTheme

/// Where a `ListGroup`'s hairline separators start.
public enum ListGroupSeparator: String, Sendable, CaseIterable {
    /// Edge to edge.
    case full
    /// From the rows' title leading edge, past the icon tile — the iOS settings look.
    case inset
}

/// A titled group of rows in one rounded surface, hairline separators between them — the fe sdk's `ListGroup`,
/// and the settings-style section of an iOS screen outside a `List`.
///
/// Rows paint the card fill themselves (`ListGroupItem`, `SwitchField`, `SelectField` do); the separators are the
/// border colour showing through the hairline gaps between them.
public struct ListGroup<Content: View>: View {
    private let title: Text?
    private let footer: Text?
    private let separator: ListGroupSeparator
    private let content: Content

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        separator: ListGroupSeparator = .full,
        @ViewBuilder content: () -> Content
    ) {
        self.init(text: title.map { Text($0) }, footer: footer.map { Text($0) }, separator: separator, content: content)
    }

    /// Renders `title` and `footer` verbatim, with no localization lookup — for strings an app already resolved.
    @_disfavoredOverload
    public init(
        _ title: String? = nil,
        footer: String? = nil,
        separator: ListGroupSeparator = .full,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            text: title.map { Text(verbatim: $0) },
            footer: footer.map { Text(verbatim: $0) },
            separator: separator,
            content: content
        )
    }

    private init(text: Text?, footer: Text?, separator: ListGroupSeparator, content: () -> Content) {
        self.title = text
        self.footer = footer
        self.separator = separator
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)

        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let title {
                title
                    .font(theme.typography.eyebrow.font)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .padding(.horizontal, theme.spacing.md)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: theme.sizes.hairline) {
                content
            }
            .backgroundPreferenceValue(RowTitleLeadingKey.self) { anchors in
                separators(anchors)
            }
            .preference(key: RowTitleLeadingKey.self, value: [])
            .clipShape(shape)
            .overlay { shape.strokeBorder(theme.colors.border.color, lineWidth: theme.sizes.hairline) }

            if let footer {
                footer
                    .font(theme.typography.caption.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, theme.spacing.md)
            }
        }
    }

    /// The colour behind the rows: the border everywhere for `.full`; for `.inset`, the card fill up to the
    /// leftmost row title, so the gaps read as separators only from there on.
    @ViewBuilder
    private func separators(_ anchors: [Anchor<CGPoint>]) -> some View {
        switch separator {
        case .full:
            theme.colors.border.color
        case .inset:
            GeometryReader { proxy in
                let inset = anchors.map { proxy[$0].x }.min() ?? theme.spacing.lg
                HStack(spacing: 0) {
                    theme.colors.card.color.frame(width: max(inset, 0))
                    theme.colors.border.color
                }
            }
        }
    }
}

/// The leading edge of every `RowLabel` title in a `ListGroup`, for its inset separators.
struct RowTitleLeadingKey: PreferenceKey {
    static let defaultValue: [Anchor<CGPoint>] = []

    static func reduce(value: inout [Anchor<CGPoint>], nextValue: () -> [Anchor<CGPoint>]) {
        value.append(contentsOf: nextValue())
    }
}
