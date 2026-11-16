import Foundation
import SwiftUI
import Testing
@testable import WoW2IosPresentation
import WoW2IosTheme

@MainActor
struct SelectionLayoutTests {
    @Test func aLongSelectionWrapsOnANarrowRowAndFitsInlineOnAWideRow() throws {
        let long = "Guidance and spoken commands together"
        let shortNarrow = try labelHeight(value: "Off", width: 225)
        let longNarrow = try labelHeight(value: long, width: 225)
        let shortWide = try labelHeight(value: "Off", width: 500)
        let longWide = try labelHeight(value: long, width: 500)

        #expect(longNarrow > shortNarrow)
        #expect(longWide == shortWide)
    }

    @Test func accessibilitySizesStackTheValueEvenWhenItFitsHorizontally() throws {
        let titleOnly = try labelHeight(value: nil, width: 600, size: .accessibility3)
        let titleAndValue = try labelHeight(value: "Off", width: 600, size: .accessibility3)

        #expect(titleAndValue > titleOnly)
    }

    @Test(arguments: [Theme.standard, .showcaseBrand], [ColorScheme.light, .dark])
    func themedLabelRendersInlineAndStacked(_ theme: Theme, _ scheme: ColorScheme) throws {
        // ImageRenderer substitutes a placeholder for UIKit controls in the gallery. Draw the same visual label here.
        let wide = try renderLabel(value: "Guidance and commands", width: 500, theme: theme, scheme: scheme)
        let narrow = try renderLabel(value: "Guidance and commands", width: 225, theme: theme, scheme: scheme)
        #expect(narrow.size.height > wide.size.height)

        if let directory = ProcessInfo.processInfo.environment["WOW2_SNAPSHOT_DIR"] {
            let root = URL(filePath: directory)
            for (name, image) in [("inline", wide), ("stacked", narrow)] {
                let png = try #require(image.pngData())
                try png.write(to: root.appending(path: "select-\(theme.id)-\(scheme)-\(name).png"))
            }
        }
    }

    @Test func aCustomLeadingViewKeepsTheIconRowsTitleInset() throws {
        let symbol: ListGroupItem<EmptyView> = ListGroupItem("Contact", systemImage: "person")
        let custom: ListGroupItem<EmptyView> = ListGroupItem("Contact", leading: Color.clear)
        let theme = Theme.standard.with(id: "wide-icon") { $0.sizes.listRowLeading = 40 }
        let titleLeading = try titleInset(of: symbol, theme: theme)
        let customLeading = try titleInset(of: custom, theme: theme)

        #expect(customLeading == titleLeading)
        #expect(customLeading == theme.spacing.lg + theme.sizes.listRowLeading + theme.spacing.md)
    }

    @Test func aNativeSelectMenuReportsItsTitleInsetOutsideTheLabelGraph() throws {
        let row = SelectField("Voice mode", systemImage: "waveform", selection: .constant("guidance"), options: [
            SelectOption("Guidance and spoken commands together", value: "guidance"),
        ])
        let theme = Theme.standard
        let inset = try titleInset(of: row, theme: theme)

        #expect(inset == theme.spacing.lg + theme.sizes.listRowLeading + theme.spacing.md)
    }

    private func labelHeight(value: String?, width: CGFloat, size: DynamicTypeSize = .large) throws -> CGFloat {
        try renderLabel(value: value, width: width, size: size).size.height
    }

    private func renderLabel(
        value: String?,
        width: CGFloat,
        size: DynamicTypeSize = .large,
        theme: Theme = .standard,
        scheme: ColorScheme = .light
    ) throws -> UIImage {
        let label = SelectFieldLabel(title: Text("Voice mode"), description: nil, systemImage: "waveform",
                                     value: value.map { Text(verbatim: $0) },
                                     appearance: .resolve(theme: theme))
            .environment(\.dynamicTypeSize, size)
            .frame(width: width)
            .background(theme.colors.card.color)
            .wow2Theme(theme)
            .environment(\.colorScheme, scheme)
        return try #require(ImageRenderer(content: label).uiImage)
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
