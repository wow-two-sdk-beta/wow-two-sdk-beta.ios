import SwiftUI
import WoW2IosTheme

/// An image tile: a media slot at a fixed aspect ratio clipped to the theme radius, a title and an optional caption
/// under it, and an optional accessory over one media corner — the fe sdk's `FeatureCard` for media.
///
/// Three forms: static, tappable (`action:`, a native `Button`) and navigating (`value:`, a `NavigationLink`). The
/// accessory sits outside the button, so a favourite star stays its own control. VoiceOver reads title and caption
/// as one element; the media is hidden.
public struct MediaCard<Media: View, Accessory: View>: View {
    private enum Interaction {
        case none
        case action(() -> Void)
        case link(@MainActor (AnyView) -> AnyView)
    }

    private let title: Text
    private let caption: Text?
    private let aspectRatio: CGFloat
    private let accessoryAlignment: Alignment
    private let interaction: Interaction
    private let media: Media
    private let accessory: Accessory

    @Environment(\.wow2Theme) private var theme

    /// - Parameters:
    ///   - aspectRatio: The media frame's width ÷ height; the media fills it and is clipped.
    ///   - accessoryAlignment: The media corner (or edge) the accessory sits on.
    ///   - action: Makes the card a button; `nil` keeps it static.
    public init(
        _ title: LocalizedStringKey,
        caption: LocalizedStringKey? = nil,
        aspectRatio: CGFloat = 1,
        accessoryAlignment: Alignment = .topTrailing,
        action: (() -> Void)? = nil,
        @ViewBuilder media: () -> Media,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.init(
            title: Text(title), caption: caption.map { Text($0) }, aspectRatio: aspectRatio,
            accessoryAlignment: accessoryAlignment, interaction: action.map(Interaction.action) ?? .none,
            media: media(), accessory: accessory()
        )
    }

    /// Renders `title` and `caption` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        caption: String? = nil,
        aspectRatio: CGFloat = 1,
        accessoryAlignment: Alignment = .topTrailing,
        action: (() -> Void)? = nil,
        @ViewBuilder media: () -> Media,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.init(
            title: Text(title), caption: caption.map { Text(verbatim: $0) }, aspectRatio: aspectRatio,
            accessoryAlignment: accessoryAlignment, interaction: action.map(Interaction.action) ?? .none,
            media: media(), accessory: accessory()
        )
    }

    /// A card that pushes `value` onto the enclosing `NavigationStack`, matched by its `navigationDestination(for:)`.
    public init<Value: Hashable>(
        _ title: LocalizedStringKey,
        caption: LocalizedStringKey? = nil,
        value: Value,
        aspectRatio: CGFloat = 1,
        accessoryAlignment: Alignment = .topTrailing,
        @ViewBuilder media: () -> Media,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.init(
            title: Text(title), caption: caption.map { Text($0) }, aspectRatio: aspectRatio,
            accessoryAlignment: accessoryAlignment, interaction: Self.link(value),
            media: media(), accessory: accessory()
        )
    }

    /// Renders `title` and `caption` verbatim, with no localization lookup; pushes `value` when tapped.
    @_disfavoredOverload
    public init<Title: StringProtocol, Value: Hashable>(
        _ title: Title,
        caption: String? = nil,
        value: Value,
        aspectRatio: CGFloat = 1,
        accessoryAlignment: Alignment = .topTrailing,
        @ViewBuilder media: () -> Media,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.init(
            title: Text(title), caption: caption.map { Text(verbatim: $0) }, aspectRatio: aspectRatio,
            accessoryAlignment: accessoryAlignment, interaction: Self.link(value),
            media: media(), accessory: accessory()
        )
    }

    private init(
        title: Text,
        caption: Text?,
        aspectRatio: CGFloat,
        accessoryAlignment: Alignment,
        interaction: Interaction,
        media: Media,
        accessory: Accessory
    ) {
        self.title = title
        self.caption = caption
        self.aspectRatio = aspectRatio
        self.accessoryAlignment = accessoryAlignment
        self.interaction = interaction
        self.media = media
        self.accessory = accessory
    }

    private static func link<Value: Hashable>(_ value: Value) -> Interaction {
        .link { label in AnyView(NavigationLink(value: value) { label }.buttonStyle(.mediaCard)) }
    }

    public var body: some View {
        let look = MediaCardAppearance.resolve(theme: theme)

        ZStack(alignment: .top) {
            interactive(content(look))
            // The accessory layer repeats the media frame, so the accessory lands on a media corner while staying
            // outside the button; the clear frame takes no touches.
            mediaFrame
                .overlay(alignment: accessoryAlignment) {
                    accessory.padding(look.accessoryInset)
                }
        }
    }

    @ViewBuilder
    private func interactive(_ content: some View) -> some View {
        switch interaction {
        case .none:
            content
        case let .action(action):
            Button(action: action) { content }
                .buttonStyle(.mediaCard)
        case let .link(makeLink):
            makeLink(AnyView(content))
        }
    }

    private var mediaFrame: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
    }

    private func content(_ look: MediaCardAppearance) -> some View {
        let shape = RoundedRectangle(cornerRadius: look.mediaRadius, style: .continuous)

        return VStack(alignment: .leading, spacing: look.spacing) {
            mediaFrame
                .background(look.mediaBackground.color)
                .overlay { media }
                .clipShape(shape)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: look.textSpacing) {
                title
                    .font(look.titleFont.font)
                    .foregroundStyle(look.title.color)
                    .multilineTextAlignment(.leading)
                if let caption {
                    caption
                        .font(look.captionFont.font)
                        .foregroundStyle(look.caption.color)
                        .multilineTextAlignment(.leading)
                        .lineLimit(look.captionLineLimit, reservesSpace: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

extension MediaCard where Accessory == EmptyView {
    public init(
        _ title: LocalizedStringKey,
        caption: LocalizedStringKey? = nil,
        aspectRatio: CGFloat = 1,
        action: (() -> Void)? = nil,
        @ViewBuilder media: () -> Media
    ) {
        self.init(title, caption: caption, aspectRatio: aspectRatio, action: action, media: media) { EmptyView() }
    }

    /// Renders `title` and `caption` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        caption: String? = nil,
        aspectRatio: CGFloat = 1,
        action: (() -> Void)? = nil,
        @ViewBuilder media: () -> Media
    ) {
        self.init(title, caption: caption, aspectRatio: aspectRatio, action: action, media: media) { EmptyView() }
    }

    public init<Value: Hashable>(
        _ title: LocalizedStringKey,
        caption: LocalizedStringKey? = nil,
        value: Value,
        aspectRatio: CGFloat = 1,
        @ViewBuilder media: () -> Media
    ) {
        self.init(title, caption: caption, value: value, aspectRatio: aspectRatio, media: media) { EmptyView() }
    }

    /// Renders `title` and `caption` verbatim, with no localization lookup; pushes `value` when tapped.
    @_disfavoredOverload
    public init<Title: StringProtocol, Value: Hashable>(
        _ title: Title,
        caption: String? = nil,
        value: Value,
        aspectRatio: CGFloat = 1,
        @ViewBuilder media: () -> Media
    ) {
        self.init(title, caption: caption, value: value, aspectRatio: aspectRatio, media: media) { EmptyView() }
    }
}
