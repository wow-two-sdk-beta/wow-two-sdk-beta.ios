import Foundation
import SwiftUI
import Testing
import WoW2IosPresentation
import WoW2IosShowcase
import WoW2IosTheme

/// Draws every component under each theme and colour scheme — a smoke test that the catalogue renders.
/// `TEST_RUNNER_WOW2_SNAPSHOT_DIR=<dir> xcodebuild … test` also writes each render there as a PNG for review.
@MainActor
@Suite("Render")
struct RenderTests {
    @Test(arguments: [Theme.standard, .showcaseBrand], [ColorScheme.light, .dark])
    func galleryRenders(_ theme: Theme, _ scheme: ColorScheme) throws {
        let gallery = ShowcaseGallery(toasts: ToastCenter())
            .padding()
            .frame(width: 393)
            .themedBackground()
            .wow2Theme(theme)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: gallery)
        renderer.scale = 1

        let image = try #require(renderer.uiImage)
        if let directory = ProcessInfo.processInfo.environment["WOW2_SNAPSHOT_DIR"], let png = image.pngData() {
            let file = URL(filePath: directory).appending(path: "gallery-\(theme.id)-\(scheme).png")
            try png.write(to: file)
        }

        #expect(image.size.width == 393)
        #expect(image.size.height > 800)
    }

    @Test func showcaseBrandClearsWcagAa() {
        #expect(ThemeContrast.failures(.showcaseBrand) == [])
    }
}

extension Theme: CustomTestStringConvertible {
    public var testDescription: String { id }
}
