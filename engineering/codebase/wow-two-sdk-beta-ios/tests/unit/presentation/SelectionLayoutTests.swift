import SwiftUI
import Testing
@testable import WoW2IosPresentation
import WoW2IosTheme

@MainActor
struct SelectionLayoutTests {
    @Test func aCustomLeadingViewKeepsTheIconRowsTitleInset() throws {
        let symbol: ListGroupItem<EmptyView> = ListGroupItem("Contact", systemImage: "person")
        let custom: ListGroupItem<EmptyView> = ListGroupItem("Contact", leading: Color.clear)
        let theme = Theme.standard.with(id: "wide-icon") { $0.sizes.listRowLeading = 40 }
        let titleLeading = try titleInset(of: symbol, theme: theme)
        let customLeading = try titleInset(of: custom, theme: theme)

        #expect(customLeading == titleLeading)
        #expect(customLeading == theme.spacing.lg + theme.sizes.listRowLeading + theme.spacing.md)
    }

    private func titleInset(of row: some View, theme: Theme) throws -> CGFloat {
        var inset: CGFloat?
        let probe = row
            .overlayPreferenceValue(RowTitleLeadingKey.self) { anchors in
                GeometryReader { geometry in
                    let _ = inset = anchors.first.map { geometry[$0].x }
                    Color.clear
                }
            }
            .frame(width: 340)
            .wow2Theme(theme)
        _ = try #require(ImageRenderer(content: probe).uiImage)
        return try #require(inset)
    }
}
