import SwiftUI
import WoW2IosTheme

/// A list of short text items, each led by a dot, an SF Symbol or its number; wrapped lines align after the marker —
/// the fe sdk's `DescriptionList` as a plain list. VoiceOver reads each item as one element.
public struct BulletList: View {
    private let items: [Text]
    private let marker: BulletListMarker
    private let tone: BulletListTone

    @Environment(\.wow2Theme) private var theme

    public init(_ items: [LocalizedStringKey], marker: BulletListMarker = .dot, tone: BulletListTone = .primary) {
        self.init(texts: items.map { Text($0) }, marker: marker, tone: tone)
    }

    /// Renders `items` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Item: StringProtocol>(
        _ items: [Item],
        marker: BulletListMarker = .dot,
        tone: BulletListTone = .primary
    ) {
        self.init(texts: items.map { Text($0) }, marker: marker, tone: tone)
    }

    private init(texts: [Text], marker: BulletListMarker, tone: BulletListTone) {
        self.items = texts
        self.marker = marker
        self.tone = tone
    }

    public var body: some View {
        let look = BulletListAppearance.resolve(theme: theme, marker: marker, tone: tone)

        VStack(alignment: .leading, spacing: look.itemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: look.markerSpacing) {
                    markerView(index: index, look: look)
                    item
                        .font(look.font.font)
                        .foregroundStyle(look.text.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private func markerView(index: Int, look: BulletListAppearance) -> some View {
        switch marker {
        case .dot:
            // A hidden glyph gives the dot the text's line box and baseline; the dot centres in it.
            Text(verbatim: "x")
                .font(look.font.font)
                .hidden()
                .overlay {
                    Circle()
                        .fill(look.marker.color)
                        .frame(width: look.dotSize, height: look.dotSize)
                }
                .accessibilityHidden(true)
        case let .symbol(name):
            Text(Image(systemName: name))
                .font(look.font.font)
                .imageScale(.small)
                .foregroundStyle(look.marker.color)
                .accessibilityHidden(true)
        case .number:
            // The widest number, hidden, sizes the column, so every item's text starts on one edge.
            Text(verbatim: "\(items.count).")
                .hidden()
                .overlay(alignment: .trailing) {
                    Text(verbatim: "\(index + 1).")
                }
                .font(look.markerFont.font.monospacedDigit())
                .foregroundStyle(look.marker.color)
        }
    }
}
