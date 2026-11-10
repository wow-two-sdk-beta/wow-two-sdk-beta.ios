import SwiftUI
import WoW2IosTheme

/// A horizontal, scrollable strip of `OptionTile`s bound to one selection, built from a collection — the fe sdk's
/// `OptionTileGroup`. It scrolls the selected tile into view on appear and on every change, jumping under Reduce
/// Motion; an optional `leading` view (an import tile, say) sits before the items.
public struct OptionTileStrip<Data: RandomAccessCollection, Value: Hashable, Leading: View, Art: View>: View
where Data.Element: Identifiable {
    private let data: Data
    @Binding private var selection: Value
    private let value: (Data.Element) -> Value
    private let title: (Data.Element) -> Text
    private let titlePosition: OptionTileTitlePosition
    private let leading: Leading
    private let art: (Data.Element) -> Art

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - value: What choosing an item sets — `\.id` when the selection is the item's id.
    ///   - title: The item's label; drawn per `titlePosition`, always read by VoiceOver.
    public init(
        _ data: Data,
        selection: Binding<Value>,
        value: @escaping (Data.Element) -> Value,
        title: @escaping (Data.Element) -> LocalizedStringKey,
        titlePosition: OptionTileTitlePosition = .below,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder art: @escaping (Data.Element) -> Art
    ) {
        self.init(
            data: data, selection: selection, value: value, title: { Text(title($0)) },
            titlePosition: titlePosition, leading: leading(), art: art
        )
    }

    /// Renders each title verbatim, with no localization lookup.
    @_disfavoredOverload
    public init(
        _ data: Data,
        selection: Binding<Value>,
        value: @escaping (Data.Element) -> Value,
        title: @escaping (Data.Element) -> String,
        titlePosition: OptionTileTitlePosition = .below,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder art: @escaping (Data.Element) -> Art
    ) {
        self.init(
            data: data, selection: selection, value: value, title: { Text(verbatim: title($0)) },
            titlePosition: titlePosition, leading: leading(), art: art
        )
    }

    private init(
        data: Data,
        selection: Binding<Value>,
        value: @escaping (Data.Element) -> Value,
        title: @escaping (Data.Element) -> Text,
        titlePosition: OptionTileTitlePosition,
        leading: Leading,
        art: @escaping (Data.Element) -> Art
    ) {
        self.data = data
        self._selection = selection
        self.value = value
        self.title = title
        self.titlePosition = titlePosition
        self.leading = leading
        self.art = art
    }

    public var body: some View {
        let look = OptionTileStripAppearance.resolve(theme: theme)

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: look.spacing) {
                    leading
                    ForEach(data) { item in
                        let itemValue = value(item)
                        OptionTile(
                            text: title(item),
                            isSelected: itemValue == selection,
                            titlePosition: titlePosition,
                            action: { selection = itemValue },
                            art: art(item)
                        )
                        .id(itemValue)
                    }
                }
                .padding(.vertical, look.verticalPadding)
            }
            .scrollClipDisabled()
            .onAppear { proxy.scrollTo(selection, anchor: .center) }
            .onChange(of: selection) { _, newValue in
                withAnimation(theme.motion.animation(.base, reduceMotion: reduceMotion)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

extension OptionTileStrip where Leading == EmptyView {
    public init(
        _ data: Data,
        selection: Binding<Value>,
        value: @escaping (Data.Element) -> Value,
        title: @escaping (Data.Element) -> LocalizedStringKey,
        titlePosition: OptionTileTitlePosition = .below,
        @ViewBuilder art: @escaping (Data.Element) -> Art
    ) {
        self.init(
            data, selection: selection, value: value, title: title, titlePosition: titlePosition,
            leading: { EmptyView() }, art: art
        )
    }

    /// Renders each title verbatim, with no localization lookup.
    @_disfavoredOverload
    public init(
        _ data: Data,
        selection: Binding<Value>,
        value: @escaping (Data.Element) -> Value,
        title: @escaping (Data.Element) -> String,
        titlePosition: OptionTileTitlePosition = .below,
        @ViewBuilder art: @escaping (Data.Element) -> Art
    ) {
        self.init(
            data, selection: selection, value: value, title: title, titlePosition: titlePosition,
            leading: { EmptyView() }, art: art
        )
    }
}
