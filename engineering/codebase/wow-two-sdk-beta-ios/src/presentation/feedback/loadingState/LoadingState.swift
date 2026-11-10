import SwiftUI
import WoW2IosTheme

/// Everything a loading state draws, resolved from the theme alone — the fe sdk's `LoadingState`.
public struct LoadingStateAppearance: Sendable, Hashable {
    public var spinner: SpinnerAppearance
    public var titleForeground: ColorToken
    public var titleFont: TypographyToken
    public var messageForeground: ColorToken
    public var messageFont: TypographyToken
    /// The gap between spinner, title and message.
    public var spacing: CGFloat
    /// The inset from the edges of the space the state fills.
    public var padding: CGFloat
    /// The card behind indicator and texts; `nil` draws none.
    public var background: ColorToken?
    /// The card's inset around its content.
    public var backgroundPadding: CGFloat
    public var radius: CGFloat

    public static func resolve(theme: Theme, tone: SpinnerTone = .neutral) -> LoadingStateAppearance {
        let colors = theme.colors
        let overMedia = tone == .overMedia
        var spinner = SpinnerAppearance.resolve(theme: theme, tone: tone, size: .large)
        // The state draws one scrim behind everything over media, not one behind the indicator alone.
        let background = spinner.background
        let backgroundPadding = spinner.padding
        spinner.background = nil
        spinner.padding = 0
        return LoadingStateAppearance(
            spinner: spinner,
            titleForeground: overMedia ? colors.scrimForeground : colors.foreground,
            titleFont: theme.typography.heading,
            messageForeground: overMedia ? colors.scrimForeground : colors.mutedForeground,
            messageFont: theme.typography.caption,
            spacing: theme.spacing.sm,
            padding: theme.spacing.xl,
            background: background,
            backgroundPadding: backgroundPadding,
            radius: spinner.radius
        )
    }
}

/// A centred spinner with an optional title and message that fills the space it is given — the fe sdk's
/// `LoadingState`. VoiceOver reads it as one element.
public struct LoadingState: View {
    private let title: Text?
    private let message: Text?
    private let tone: SpinnerTone

    @Environment(\.wow2Theme) private var theme

    public init(_ title: LocalizedStringKey? = nil, message: LocalizedStringKey? = nil, tone: SpinnerTone = .neutral) {
        self.title = title.map { Text($0) }
        self.message = message.map { Text($0) }
        self.tone = tone
    }

    /// Renders `title` and `message` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(_ title: Title, message: String? = nil, tone: SpinnerTone = .neutral) {
        self.title = Text(title)
        self.message = message.map { Text(verbatim: $0) }
        self.tone = tone
    }

    public var body: some View {
        let look = LoadingStateAppearance.resolve(theme: theme, tone: tone)

        VStack(spacing: look.spacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(look.spinner.size.controlSize)
                .tint(look.spinner.tint.color)
            if let title {
                title
                    .font(look.titleFont.font)
                    .foregroundStyle(look.titleForeground.color)
            }
            if let message {
                message
                    .font(look.messageFont.font)
                    .foregroundStyle(look.messageForeground.color)
            }
        }
        .multilineTextAlignment(.center)
        .padding(look.background == nil ? 0 : look.backgroundPadding)
        .background {
            if let background = look.background {
                RoundedRectangle(cornerRadius: look.radius, style: .continuous).fill(background.color)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(look.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
