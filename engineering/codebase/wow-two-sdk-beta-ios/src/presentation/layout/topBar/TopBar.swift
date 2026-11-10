import SwiftUI
import WoW2IosTheme

/// A header row for a full-screen cover or sheet with no navigation bar: a centred title, with an optional subtitle
/// under it, between a leading and a trailing slot — usually icon buttons or a `Menu`. The top-edge counterpart of
/// `ActionBar`.
///
/// The title stays centred on the bar whatever the slots' widths, and truncates to one line before it reaches
/// them. The bar draws no background, so it sits on a page, a sheet or a dark media screen alike.
///
/// A bar with one slot names it: `TopBar("Title", trailing: { … })` — an unlabelled lone closure is ambiguous.
public struct TopBar<Leading: View, Trailing: View>: View {
    private let title: Text
    private let subtitle: Text?
    private let isInset: Bool
    private let leading: Leading
    private let trailing: Trailing

    @Environment(\.wow2Theme) private var theme

    /// - Parameter isInset: `false` drops the bar's horizontal padding, for a container that already pads its
    ///   content.
    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        isInset: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), subtitle: subtitle.map { Text($0) }, isInset: isInset,
            leading: leading(), trailing: trailing()
        )
    }

    /// Renders `title` and `subtitle` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        subtitle: String? = nil,
        isInset: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            text: Text(title), subtitle: subtitle.map { Text(verbatim: $0) }, isInset: isInset,
            leading: leading(), trailing: trailing()
        )
    }

    fileprivate init(text: Text, subtitle: Text?, isInset: Bool, leading: Leading, trailing: Trailing) {
        self.title = text
        self.subtitle = subtitle
        self.isInset = isInset
        self.leading = leading
        self.trailing = trailing
    }

    public var body: some View {
        let look = TopBarAppearance.resolve(theme: theme, isInset: isInset)

        TopBarLayout(spacing: look.slotSpacing) {
            HStack(spacing: look.slotSpacing) { leading }
            VStack(spacing: look.titleSpacing) {
                title
                    .font(look.titleFont.font)
                    .foregroundStyle(look.title.color)
                    .lineLimit(1)
                if let subtitle {
                    subtitle
                        .font(look.subtitleFont.font)
                        .foregroundStyle(look.subtitle.color)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            HStack(spacing: look.slotSpacing) { trailing }
        }
        .frame(minHeight: look.minHeight)
        .padding(.horizontal, look.horizontalPadding)
    }
}

extension TopBar where Leading == EmptyView {
    /// A bar with only a trailing slot.
    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        isInset: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: { EmptyView() }, trailing: trailing)
    }

    /// A bar with only a trailing slot; renders `title` and `subtitle` verbatim.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        subtitle: String? = nil,
        isInset: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: { EmptyView() }, trailing: trailing)
    }
}

extension TopBar where Trailing == EmptyView {
    /// A bar with only a leading slot.
    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        isInset: Bool = true,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: leading, trailing: { EmptyView() })
    }

    /// A bar with only a leading slot; renders `title` and `subtitle` verbatim.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        subtitle: String? = nil,
        isInset: Bool = true,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: leading, trailing: { EmptyView() })
    }
}

extension TopBar where Leading == EmptyView, Trailing == EmptyView {
    /// A bar holding the title alone.
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, isInset: Bool = true) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: { EmptyView() }, trailing: { EmptyView() })
    }

    /// A bar holding the title alone; renders `title` and `subtitle` verbatim.
    @_disfavoredOverload
    public init<Title: StringProtocol>(_ title: Title, subtitle: String? = nil, isInset: Bool = true) {
        self.init(title, subtitle: subtitle, isInset: isInset, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

/// Places three subviews — leading slot, title, trailing slot — with the title centred on the whole width and given
/// only the room the wider slot leaves on both sides, so it stays centred and truncates before it reaches a slot.
/// SwiftUI mirrors it under right-to-left layout.
private struct TopBarLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 3 else { return .zero }
        let leading = subviews[0].sizeThatFits(.unspecified)
        let trailing = subviews[2].sizeThatFits(.unspecified)
        let side = max(leading.width, trailing.width)
        let width: CGFloat
        if let proposed = proposal.width, proposed.isFinite {
            width = proposed
        } else {
            width = 2 * sideRoom(side) + subviews[1].sizeThatFits(.unspecified).width
        }
        let title = subviews[1].sizeThatFits(ProposedViewSize(width: titleWidth(in: width, side: side), height: nil))
        return CGSize(width: width, height: max(leading.height, trailing.height, title.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let leading = subviews[0].sizeThatFits(.unspecified)
        let trailing = subviews[2].sizeThatFits(.unspecified)
        let side = max(leading.width, trailing.width)
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(leading)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.midX, y: bounds.midY),
            anchor: .center,
            proposal: ProposedViewSize(width: titleWidth(in: bounds.width, side: side), height: nil)
        )
        subviews[2].place(
            at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: ProposedViewSize(trailing)
        )
    }

    private func titleWidth(in width: CGFloat, side: CGFloat) -> CGFloat {
        max(0, width - 2 * sideRoom(side))
    }

    /// The width a slot reserves on each side of the title: the wider slot plus the gap, or nothing with no slots.
    private func sideRoom(_ side: CGFloat) -> CGFloat {
        side > 0 ? side + spacing : 0
    }
}
