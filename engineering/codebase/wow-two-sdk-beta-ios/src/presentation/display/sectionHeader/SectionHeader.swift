import SwiftUI
import WoW2IosTheme

/// A section's heading with an optional subtitle and a trailing control — the fe sdk's `SectionHeader`.
public struct SectionHeader<Trailing: View>: View {
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey?
    private let trailing: Trailing

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.heading.font)
                    .foregroundStyle(theme.colors.foreground.color)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.caption.font)
                        .foregroundStyle(theme.colors.mutedForeground.color)
                }
            }
            Spacer(minLength: theme.spacing.sm)
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}
