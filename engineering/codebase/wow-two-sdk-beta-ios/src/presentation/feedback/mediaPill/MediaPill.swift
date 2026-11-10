import SwiftUI
import WoW2IosTheme

/// A status pill shown over media — a camera viewfinder, a full-screen picture: a title, an optional leading
/// SF Symbol and a tone, legible over any picture. VoiceOver reads it as one static text.
public struct MediaPill: View {
    private let title: Text
    private let systemImage: String?
    private let tone: MediaPillTone
    private let size: MediaPillSize

    @Environment(\.wow2Theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        tone: MediaPillTone = .neutral,
        size: MediaPillSize = .medium
    ) {
        self.init(text: Text(title), systemImage: systemImage, tone: tone, size: size)
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        systemImage: String? = nil,
        tone: MediaPillTone = .neutral,
        size: MediaPillSize = .medium
    ) {
        self.init(text: Text(title), systemImage: systemImage, tone: tone, size: size)
    }

    private init(text: Text, systemImage: String?, tone: MediaPillTone, size: MediaPillSize) {
        self.title = text
        self.systemImage = systemImage
        self.tone = tone
        self.size = size
    }

    public var body: some View {
        let look = MediaPillAppearance.resolve(theme: theme, tone: tone, size: size)

        HStack(spacing: look.spacing) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            title
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(look.font.font)
        .foregroundStyle(look.foreground.color)
        .padding(.horizontal, look.horizontalPadding)
        .padding(.vertical, look.verticalPadding)
        .frame(minHeight: look.minHeight)
        .background { Capsule().fill(look.background.color) }
        .accessibilityElement(children: .combine)
    }
}
