import SwiftUI
import WoW2IosTheme

/// A banner's severity — the fe sdk's `Severity`. Every tone but `neutral` shows its glyph, so severity never rests
/// on colour alone.
public enum BannerTone: String, Sendable, CaseIterable {
    case neutral, info, success, warning, danger

    /// The theme tone family, `nil` for neutral.
    public var tone: Tone? {
        switch self {
        case .neutral: nil
        case .info: .info
        case .success: .success
        case .warning: .warning
        case .danger: .destructive
        }
    }

    public var systemImage: String? {
        switch self {
        case .neutral: nil
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        }
    }
}

/// Everything a banner draws, resolved from the theme alone.
public struct BannerAppearance: Sendable, Hashable {
    public var background: ColorToken
    public var border: ColorToken
    /// The glyph, the title and the action.
    public var accent: ColorToken
    public var title: ColorToken
    public var message: ColorToken
    public var radius: CGFloat
    public var padding: CGFloat

    public static func resolve(theme: Theme, tone: BannerTone) -> BannerAppearance {
        let colors = theme.colors
        guard let family = tone.tone.map({ colors[$0] }) else {
            return BannerAppearance(
                background: colors.muted, border: colors.border, accent: colors.foreground,
                title: colors.foreground, message: colors.mutedForeground,
                radius: theme.radii.lg, padding: theme.spacing.md
            )
        }
        return BannerAppearance(
            background: family.soft, border: family.base.opacity(0.35), accent: family.softForeground,
            title: family.softForeground, message: family.softForeground,
            radius: theme.radii.lg, padding: theme.spacing.md
        )
    }
}

/// An inline alert inside a screen: the severity glyph, an optional title, the message, an optional action and an
/// optional dismiss button — the fe sdk's `Banner` / `Alert`.
public struct Banner: View {
    private let tone: BannerTone
    private let title: Text?
    private let message: Text
    private let actionTitle: Text?
    private let action: (@MainActor () -> Void)?
    private let onDismiss: (@MainActor () -> Void)?

    @Environment(\.wow2Theme) private var theme

    /// - Parameters:
    ///   - actionTitle: Shows a text button below the message when `action` is set too.
    ///   - onDismiss: Shows a close button that runs it.
    public init(
        tone: BannerTone = .info,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (@MainActor () -> Void)? = nil,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            tone: tone, title: title.map { Text($0) }, text: Text(message), actionTitle: actionTitle.map { Text($0) },
            action: action, onDismiss: onDismiss
        )
    }

    /// Renders `title`, `message` and `actionTitle` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Message: StringProtocol>(
        tone: BannerTone = .info,
        title: String? = nil,
        message: Message,
        actionTitle: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        self.init(
            tone: tone, title: title.map { Text(verbatim: $0) }, text: Text(message),
            actionTitle: actionTitle.map { Text(verbatim: $0) }, action: action, onDismiss: onDismiss
        )
    }

    private init(
        tone: BannerTone,
        title: Text?,
        text: Text,
        actionTitle: Text?,
        action: (@MainActor () -> Void)?,
        onDismiss: (@MainActor () -> Void)?
    ) {
        self.tone = tone
        self.title = title
        self.message = text
        self.actionTitle = actionTitle
        self.action = action
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let look = BannerAppearance.resolve(theme: theme, tone: tone)
        let shape = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        HStack(alignment: .top, spacing: theme.spacing.sm) {
            if let systemImage = tone.systemImage {
                Image(systemName: systemImage)
                    .font(theme.typography.label.font)
                    .foregroundStyle(look.accent.color)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    if let title {
                        title
                            .font(theme.typography.label.font.weight(.semibold))
                            .foregroundStyle(look.title.color)
                    }
                    message
                        .font(theme.typography.caption.font)
                        .foregroundStyle(look.message.color)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                if let actionTitle, let action {
                    Button(action: action) {
                        actionTitle
                            .font(theme.typography.label.font.weight(.semibold))
                            .foregroundStyle(look.accent.color)
                            .underline()
                            .frame(minHeight: theme.sizes.controlMedium)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -theme.spacing.sm)
                    .padding(.top, theme.spacing.xs)
                }
            }
            Spacer(minLength: 0)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(look.accent.color)
                        .frame(width: theme.sizes.controlMedium, height: theme.sizes.controlMedium)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Dismiss"))
                .padding(-theme.spacing.md)
            }
        }
        .padding(look.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { shape.fill(look.background.color) }
        .overlay { shape.strokeBorder(look.border.color, lineWidth: theme.sizes.hairline) }
        .accessibilityElement(children: .contain)
    }
}
