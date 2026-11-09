import SwiftUI
import WoW2IosTheme

/// A non-interactive pill marking a status or category, with an optional leading dot (the status-pill form) or
/// SF Symbol — the fe sdk's `Badge`. VoiceOver reads it as one static text.
public struct Badge: View {
    private let title: Text
    private let tone: BadgeTone
    private let variant: BadgeVariant
    private let size: BadgeSize
    private let systemImage: String?
    private let showsDot: Bool

    @Environment(\.wow2Theme) private var theme

    /// - Parameter showsDot: Leads with a dot in the tone — the status pill; ignored when `systemImage` is set.
    public init(
        _ title: LocalizedStringKey,
        tone: BadgeTone = .neutral,
        variant: BadgeVariant = .soft,
        size: BadgeSize = .medium,
        systemImage: String? = nil,
        showsDot: Bool = false
    ) {
        self.init(
            text: Text(title), tone: tone, variant: variant, size: size, systemImage: systemImage, showsDot: showsDot
        )
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        tone: BadgeTone = .neutral,
        variant: BadgeVariant = .soft,
        size: BadgeSize = .medium,
        systemImage: String? = nil,
        showsDot: Bool = false
    ) {
        self.init(
            text: Text(title), tone: tone, variant: variant, size: size, systemImage: systemImage, showsDot: showsDot
        )
    }

    private init(
        text: Text,
        tone: BadgeTone,
        variant: BadgeVariant,
        size: BadgeSize,
        systemImage: String?,
        showsDot: Bool
    ) {
        self.title = text
        self.tone = tone
        self.variant = variant
        self.size = size
        self.systemImage = systemImage
        self.showsDot = showsDot
    }

    public var body: some View {
        let look = BadgeAppearance.resolve(theme: theme, tone: tone, variant: variant, size: size)

        HStack(spacing: look.spacing) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            } else if showsDot {
                Circle()
                    .fill(look.dot.color)
                    .frame(width: look.dotSize, height: look.dotSize)
                    .accessibilityHidden(true)
            }
            title
                .lineLimit(1)
        }
        .font(look.font.font)
        .foregroundStyle(look.foreground.color)
        .padding(.horizontal, look.horizontalPadding)
        .frame(minHeight: look.height)
        .background { Capsule().fill(look.background?.color ?? .clear) }
        .overlay {
            if let border = look.border {
                Capsule().strokeBorder(border.color, lineWidth: theme.sizes.hairline)
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}
