import SwiftUI
import WoW2IosTheme

/// One row of a `ListGroup`: an optional leading tile, a title, an optional description and a trailing view — the
/// fe sdk's `ListGroupItem`. With an `action` the whole row is one button with a chevron.
public struct ListGroupItem<Trailing: View>: View {
    private let title: Text
    private let description: Text?
    private let systemImage: String?
    private let leading: AnyView?
    private let action: (@MainActor () -> Void)?
    private let trailing: Trailing

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), description: description.map { Text($0) }, systemImage: systemImage, action: action,
            trailing: trailing
        )
    }

    /// Renders `title` and `description` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        description: String? = nil,
        systemImage: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), description: description.map { Text(verbatim: $0) }, systemImage: systemImage,
            action: action, trailing: trailing
        )
    }

    /// Shows a decorative view in the same leading slot as a system image.
    public init<Leading: View>(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        leading: Leading,
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), description: description.map { Text($0) }, systemImage: nil,
            leading: AnyView(leading), action: action, trailing: trailing
        )
    }

    /// Renders `title` and `description` verbatim.
    @_disfavoredOverload
    public init<Title: StringProtocol, Leading: View>(
        _ title: Title,
        description: String? = nil,
        leading: Leading,
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), description: description.map { Text(verbatim: $0) }, systemImage: nil,
            leading: AnyView(leading), action: action, trailing: trailing
        )
    }

    private init(
        text: Text,
        description: Text?,
        systemImage: String?,
        leading: AnyView? = nil,
        action: (@MainActor () -> Void)?,
        trailing: () -> Trailing
    ) {
        self.title = text
        self.description = description
        self.systemImage = systemImage
        self.leading = leading
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                row(showsChevron: true)
            }
            .buttonStyle(RowPressStyle())
        } else {
            row(showsChevron: false)
                .background(theme.colors.card.color)
        }
    }

    private func row(showsChevron: Bool) -> some View {
        HStack(spacing: theme.spacing.md) {
            // The title keeps its line: a trailing value that is a few points too wide shrinks before the title wraps.
            RowLabel(title: title, description: description, systemImage: systemImage, leading: leading)
                .layoutPriority(1)
            Spacer(minLength: theme.spacing.sm)
            trailing
                .font(theme.typography.label.font)
                .foregroundStyle(theme.colors.mutedForeground.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.colors.subtleForeground.color)
                    .accessibilityHidden(true)
            }
        }
        .rowPadding(theme)
    }
}

extension ListGroupItem where Trailing == EmptyView {
    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.init(title, description: description, systemImage: systemImage, action: action) { EmptyView() }
    }

    /// Renders `title` and `description` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        description: String? = nil,
        systemImage: String? = nil,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.init(title, description: description, systemImage: systemImage, action: action) { EmptyView() }
    }

    public init<Leading: View>(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        leading: Leading,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.init(title, description: description, leading: leading, action: action) { EmptyView() }
    }

    /// Renders `title` and `description` verbatim.
    @_disfavoredOverload
    public init<Title: StringProtocol, Leading: View>(
        _ title: Title,
        description: String? = nil,
        leading: Leading,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.init(title, description: description, leading: leading, action: action) { EmptyView() }
    }
}

/// The row's leading tile, title and description. Reports the title's leading edge for inset separators.
struct RowLabel: View {
    let title: Text
    let description: Text?
    let systemImage: String?
    var leading: AnyView? = nil

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        let side = theme.sizes.listRowLeading

        HStack(spacing: theme.spacing.md) {
            if let leading {
                leading
                    .frame(width: side, height: side)
                    .clipped()
                    .accessibilityHidden(true)
            } else if let systemImage {
                RowIconTile(systemImage: systemImage)
            }
            RowTitle(title: title, description: description)
                .anchorPreference(key: RowTitleLeadingKey.self, value: .leading) { [$0] }
        }
    }
}

struct RowTitle: View {
    let title: Text
    let description: Text?

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            title
                .font(theme.typography.label.font)
                .foregroundStyle(theme.colors.foreground.color)
            if let description {
                description
                    .font(theme.typography.caption.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
            }
        }
    }
}

struct RowIconTile: View {
    let systemImage: String

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        let side = theme.sizes.listRowLeading

        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.colors.primary.softForeground.color)
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous)
                    .fill(theme.colors.primary.soft.color)
            )
            .accessibilityHidden(true)
    }
}

/// The card fill, darkening to muted while pressed.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RowPressBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

private struct RowPressBody<Label: View>: View {
    let label: Label
    let isPressed: Bool

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        label
            .contentShape(Rectangle())
            .background((isPressed ? theme.colors.muted : theme.colors.card).color)
    }
}

extension View {
    /// The row insets every `ListGroup` row shares, at least one medium control tall.
    func rowPadding(_ theme: Theme) -> some View {
        padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .frame(maxWidth: .infinity, minHeight: theme.sizes.controlMedium + theme.spacing.xs, alignment: .leading)
    }
}
