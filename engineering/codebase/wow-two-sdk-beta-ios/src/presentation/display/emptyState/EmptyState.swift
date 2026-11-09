import SwiftUI
import WoW2IosTheme

/// What a screen shows when it has nothing to list: an icon, a title, a line of guidance and the actions that
/// fill it — the fe sdk's `EmptyState`.
public struct EmptyState<Actions: View>: View {
    private let title: Text
    private let systemImage: String
    private let message: Text?
    private let actions: Actions

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        systemImage: String,
        message: LocalizedStringKey? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.message = message.map { Text($0) }
        self.actions = actions()
    }

    /// Renders `title` and `message` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        systemImage: String,
        message: String? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.message = message.map { Text(verbatim: $0) }
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(theme.colors.mutedForeground.color)
                .frame(width: 64, height: 64)
                .background(Circle().fill(theme.colors.muted.color))
                .accessibilityHidden(true)
                .padding(.bottom, theme.spacing.xs)

            title
                .font(theme.typography.heading.font)
                .foregroundStyle(theme.colors.foreground.color)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if let message {
                message
                    .font(theme.typography.body.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            actions
                .padding(.top, theme.spacing.sm)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

extension EmptyState where Actions == EmptyView {
    public init(_ title: LocalizedStringKey, systemImage: String, message: LocalizedStringKey? = nil) {
        self.init(title, systemImage: systemImage, message: message) { EmptyView() }
    }

    /// Renders `title` and `message` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(_ title: Title, systemImage: String, message: String? = nil) {
        self.init(title, systemImage: systemImage, message: message) { EmptyView() }
    }
}
