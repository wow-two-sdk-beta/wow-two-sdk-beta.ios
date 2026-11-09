import SwiftUI
import WoW2IosTheme

/// The avatar side, read from `Theme.sizes` — the fe sdk's `Avatar` size steps.
public enum AvatarSize: String, Sendable, CaseIterable {
    case small, medium, large, extraLarge
}

/// The avatar silhouette — the fe sdk's `AvatarShape`.
public enum AvatarShape: String, Sendable, CaseIterable {
    case circle, square
}

/// The initials tile's colour — the fe sdk's `AvatarTone`.
public enum AvatarTone: String, Sendable, CaseIterable {
    case neutral, primary, success, warning, danger
}

/// Everything an avatar draws, resolved from the theme alone — the fe sdk's `Avatar.variants.ts`.
public struct AvatarAppearance: Sendable, Hashable {
    public var side: CGFloat
    public var radius: CGFloat
    public var background: ColorToken
    public var foreground: ColorToken
    /// The initials' point size: a fixed share of the side, since the tile does not grow with Dynamic Type.
    public var initialsSize: CGFloat
    public var initialsWeight: Font.Weight
    public var initialsDesign: Font.Design

    public static func resolve(
        theme: Theme,
        size: AvatarSize = .medium,
        shape: AvatarShape = .circle,
        tone: AvatarTone = .neutral
    ) -> AvatarAppearance {
        let colors = theme.colors
        let side: CGFloat = switch size {
        case .small: theme.sizes.avatarSmall
        case .medium: theme.sizes.avatarMedium
        case .large: theme.sizes.avatarLarge
        case .extraLarge: theme.sizes.avatarExtraLarge
        }
        let (background, foreground): (ColorToken, ColorToken) = switch tone {
        case .neutral: (colors.muted, colors.mutedForeground)
        case .primary: (colors.primary.soft, colors.primary.softForeground)
        case .success: (colors.success.soft, colors.success.softForeground)
        case .warning: (colors.warning.soft, colors.warning.softForeground)
        case .danger: (colors.destructive.soft, colors.destructive.softForeground)
        }
        return AvatarAppearance(
            side: side,
            radius: shape == .circle ? side / 2 : (size == .small ? theme.radii.md : theme.radii.lg),
            background: background,
            foreground: foreground,
            initialsSize: (side * 0.4).rounded(),
            initialsWeight: .semibold,
            initialsDesign: theme.typography.label.design
        )
    }
}

/// A person's picture, or their initials in a tinted tile when there is none — the fe sdk's `Avatar`.
/// VoiceOver reads the name as an image.
public struct Avatar: View {
    private enum Source {
        case image(Image)
        case url(URL)
        case none
    }

    private let source: Source
    private let name: String
    private let size: AvatarSize
    private let shape: AvatarShape
    private let tone: AvatarTone

    @Environment(\.wow2Theme) private var theme

    /// - Parameter name: The person's name: the initials and the accessibility label.
    public init(
        _ name: String,
        image: Image? = nil,
        size: AvatarSize = .medium,
        shape: AvatarShape = .circle,
        tone: AvatarTone = .neutral
    ) {
        self.source = image.map { .image($0) } ?? .none
        self.name = name
        self.size = size
        self.shape = shape
        self.tone = tone
    }

    /// Loads the picture from `url`, showing the initials while it loads and when it fails.
    public init(
        _ name: String,
        url: URL?,
        size: AvatarSize = .medium,
        shape: AvatarShape = .circle,
        tone: AvatarTone = .neutral
    ) {
        self.source = url.map { .url($0) } ?? .none
        self.name = name
        self.size = size
        self.shape = shape
        self.tone = tone
    }

    /// Up to two initials: the first letters of the first and last words, upper-cased.
    nonisolated public static func initials(from name: String) -> String {
        let words = name.split(whereSeparator: { $0.isWhitespace || $0 == "-" }).filter { !$0.isEmpty }
        guard let first = words.first?.first else { return "" }
        guard words.count > 1, let last = words.last?.first else { return String(first).uppercased() }
        return (String(first) + String(last)).uppercased()
    }

    public var body: some View {
        let look = AvatarAppearance.resolve(theme: theme, size: size, shape: shape, tone: tone)
        let tile = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        Group {
            switch source {
            case .image(let image):
                image.resizable().scaledToFill()
            case .url(let url):
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder(look)
                    }
                }
            case .none:
                placeholder(look)
            }
        }
        .frame(width: look.side, height: look.side)
        .clipShape(tile)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: name))
        .accessibilityAddTraits(.isImage)
    }

    private func placeholder(_ look: AvatarAppearance) -> some View {
        let initials = Self.initials(from: name)
        return ZStack {
            look.background.color
            if initials.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: look.initialsSize, weight: look.initialsWeight))
            } else {
                Text(verbatim: initials)
                    .font(.system(size: look.initialsSize, weight: look.initialsWeight, design: look.initialsDesign))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(look.foreground.color)
    }
}
