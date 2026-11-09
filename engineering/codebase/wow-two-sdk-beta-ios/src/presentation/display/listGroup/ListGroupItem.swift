import SwiftUI
import WoW2IosTheme

/// One row of a `ListGroup`: an optional icon tile, a title, an optional description and a trailing view — the
/// fe sdk's `ListGroupItem`. With an `action` the whole row is one button with a chevron.
public struct ListGroupItem<Trailing: View>: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let systemImage: String?
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
        self.title = title
        self.description = description
        self.systemImage = systemImage
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
            RowLabel(title: title, description: description, systemImage: systemImage)
            Spacer(minLength: theme.spacing.sm)
            trailing
                .font(theme.typography.label.font)
                .foregroundStyle(theme.colors.mutedForeground.color)
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
}

/// The row's leading icon tile, title and description; shared by `ListGroupItem` and `SwitchField`.
struct RowLabel: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let systemImage: String?

    @Environment(\.wow2Theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.colors.primary.softForeground.color)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous)
                            .fill(theme.colors.primary.soft.color)
                    )
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.label.font)
                    .foregroundStyle(theme.colors.foreground.color)
                if let description {
                    Text(description)
                        .font(theme.typography.caption.font)
                        .foregroundStyle(theme.colors.mutedForeground.color)
                }
            }
        }
    }
}

/// The card fill, darkening to muted while pressed.
private struct RowPressStyle: ButtonStyle {
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
