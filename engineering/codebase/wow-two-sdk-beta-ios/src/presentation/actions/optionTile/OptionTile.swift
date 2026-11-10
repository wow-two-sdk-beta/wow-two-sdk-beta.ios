import SwiftUI
import WoW2IosTheme

/// A selectable tile: art the caller draws, a title under or over it, a `primary` ring plus a checkmark badge when
/// selected — the fe sdk's `OptionTile`. VoiceOver reads it as one button with the title and the selected trait.
///
/// The art sets the tile's size (give it a `frame`); the tile clips it to the theme's `lg` radius.
public struct OptionTile<Art: View>: View {
    private let title: Text
    private let isSelected: Bool
    private let titlePosition: OptionTileTitlePosition
    private let action: @MainActor () -> Void
    private let art: Art

    public init(
        _ title: LocalizedStringKey,
        isSelected: Bool,
        titlePosition: OptionTileTitlePosition = .below,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder art: () -> Art
    ) {
        self.init(text: Text(title), isSelected: isSelected, titlePosition: titlePosition, action: action, art: art())
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        isSelected: Bool,
        titlePosition: OptionTileTitlePosition = .below,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder art: () -> Art
    ) {
        self.init(text: Text(title), isSelected: isSelected, titlePosition: titlePosition, action: action, art: art())
    }

    init(
        text: Text,
        isSelected: Bool,
        titlePosition: OptionTileTitlePosition,
        action: @escaping @MainActor () -> Void,
        art: Art
    ) {
        self.title = text
        self.isSelected = isSelected
        self.titlePosition = titlePosition
        self.action = action
        self.art = art
    }

    public var body: some View {
        Button(action: action) {
            art
        }
        .buttonStyle(OptionTileStyle(title: title, isSelected: isSelected, titlePosition: titlePosition))
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OptionTileStyle: ButtonStyle {
    let title: Text
    let isSelected: Bool
    let titlePosition: OptionTileTitlePosition

    func makeBody(configuration: Configuration) -> some View {
        OptionTileBody(
            art: configuration.label,
            title: title,
            isSelected: isSelected,
            isPressed: configuration.isPressed,
            titlePosition: titlePosition
        )
    }
}

private struct OptionTileBody<Art: View>: View {
    let art: Art
    let title: Text
    let isSelected: Bool
    let isPressed: Bool
    let titlePosition: OptionTileTitlePosition

    @Environment(\.wow2Theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let look = OptionTileAppearance.resolve(
            theme: theme, isSelected: isSelected, isPressed: isPressed, isEnabled: isEnabled
        )
        let shape = RoundedRectangle(cornerRadius: look.radius, style: .continuous)

        OptionTileStack(spacing: look.spacing, titleFirst: titlePosition == .above) {
            art
                .frame(minWidth: look.minimumSide, minHeight: look.minimumSide)
                .clipShape(shape)
                .overlay {
                    if let wash = look.pressedWash { shape.fill(wash.color) }
                }
                .overlay { shape.strokeBorder(look.border.color, lineWidth: look.borderWidth) }
                .overlay(alignment: .topTrailing) {
                    if look.showsCheckmark { checkmark(look) }
                }
                .scaleEffect(reduceMotion ? 1 : look.scale)
                .accessibilityHidden(true)

            if titlePosition != .hidden {
                title
                    .font(look.titleFont.font)
                    .foregroundStyle(look.title.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .opacity(look.opacity)
        .contentShape(Rectangle())
        .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isSelected)
        .animation(theme.motion.animation(.fast, reduceMotion: reduceMotion), value: isPressed)
    }

    private func checkmark(_ look: OptionTileAppearance) -> some View {
        Image(systemName: "checkmark")
            .font(look.checkmarkFont.font)
            .foregroundStyle(look.checkmarkForeground.color)
            .frame(width: look.checkmarkSize, height: look.checkmarkSize)
            .background { Circle().fill(look.checkmarkBackground.color) }
            .overlay { Circle().strokeBorder(look.checkmarkBorder.color, lineWidth: theme.sizes.ring) }
            .padding(look.checkmarkInset)
            .transition(.scale.combined(with: .opacity))
            .accessibilityHidden(true)
    }
}

/// The art, then the title wrapped to the art's width — above it when `titleFirst`. A plain `VStack` would let a
/// long title widen the tile in a horizontal scroll view.
private struct OptionTileStack: Layout {
    let spacing: CGFloat
    let titleFirst: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (art, title) = sizes(proposal: proposal, subviews: subviews)
        guard let title else { return art }
        return CGSize(width: art.width, height: art.height + spacing + title.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let first = subviews.first else { return }
        let (art, title) = sizes(proposal: proposal, subviews: subviews)
        let artY = titleFirst ? bounds.minY + (title.map { $0.height + spacing } ?? 0) : bounds.minY
        first.place(
            at: CGPoint(x: bounds.midX, y: artY), anchor: .top, proposal: ProposedViewSize(art)
        )
        if let title, subviews.count > 1 {
            let titleY = titleFirst ? bounds.minY : bounds.minY + art.height + spacing
            subviews[1].place(
                at: CGPoint(x: bounds.midX, y: titleY), anchor: .top, proposal: ProposedViewSize(title)
            )
        }
    }

    private func sizes(proposal: ProposedViewSize, subviews: Subviews) -> (CGSize, CGSize?) {
        guard let first = subviews.first else { return (.zero, nil) }
        let art = first.sizeThatFits(proposal)
        guard subviews.count > 1 else { return (art, nil) }
        let title = subviews[1].sizeThatFits(ProposedViewSize(width: art.width, height: nil))
        return (art, title)
    }
}
