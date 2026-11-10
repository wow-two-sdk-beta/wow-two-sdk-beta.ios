import SwiftUI
import Testing
import WoW2IosTheme

@Suite("Theme")
struct ThemeTests {
    @Test func standardMirrorsFeSdkTokens() {
        let colors = Theme.standard.colors
        #expect(colors.primary.base.light.hex == "#2563eb")
        #expect(colors.primary.base.dark.hex == "#3b82f6")
        #expect(colors.background.dark.hex == "#09090b")
        #expect(colors.destructive.soft.light.hex == "#fef2f2")
        #expect(Theme.standard.radii.md == 8)
        #expect(Theme.standard.motion.duration(.base) == 0.2)
    }

    @Test func standardClearsWcagAaInBothModes() {
        #expect(ThemeContrast.failures(.standard) == [])
    }

    @Test func contrastCatchesUnreadablePair() {
        let broken = Theme.standard.with(id: "broken") { $0.colors.primary.foreground = $0.colors.primary.base }
        let failures = ThemeContrast.failures(broken)
        #expect(failures.contains { $0.contains("primary.foreground on primary") })
    }

    @Test func scrimKeepsOneValueInBothModes() {
        let colors = Theme.standard.colors
        #expect(colors.scrim.light == colors.scrim.dark)
        #expect(abs(colors.scrim.light.alpha - 0x99 / 255.0) < 0.001)
        #expect(colors.scrimForeground.resolve(.dark).hex == "#ffffff")
    }

    @Test func contrastChecksScrimOverWhitePicture() {
        let faint = Theme.standard.with(id: "faint") { $0.colors.scrim = ColorToken("#00000020") }
        #expect(ThemeContrast.failures(faint).contains { $0.contains("scrimForeground on scrim") })
    }

    @Test func compositingBlendsByAlpha() {
        let grey = RGBA(hex: "#00000080").composited(over: RGBA(hex: "#ffffff"))
        #expect(grey.alpha == 1)
        #expect(abs(grey.red - (1 - 128.0 / 255)) < 0.001)
    }

    @Test func contrastRatioMatchesWcag() {
        let ratio = ThemeContrast.ratio(RGBA(hex: "#000000"), RGBA(hex: "#ffffff"))
        #expect(abs(ratio - 21) < 0.01)
    }

    @Test(arguments: ["#2563eb", "2563eb", "#2563ebff"])
    func readsHex(_ hex: String) {
        let color = RGBA(hex: hex)
        #expect(color.hex == "#2563eb")
        #expect(color.alpha == 1)
    }

    @Test func readsHexAlpha() {
        #expect(abs(RGBA(hex: "#00000080").alpha - 128.0 / 255) < 0.001)
    }

    @Test func tokenResolvesPerScheme() {
        let token = ColorToken("#ffffff", "#000000")
        #expect(token.resolve(.light).hex == "#ffffff")
        #expect(token.resolve(.dark).hex == "#000000")
        #expect(token.opacity(0.5).resolve(.dark).alpha == 0.5)
    }

    @Test func toneSubscriptReadsAndWrites() {
        var colors = ThemeColors.standard
        let violet = ToneColors(base: ColorToken("#7c3aed"), foreground: ColorToken("#ffffff"),
                                soft: ColorToken("#ede9fe"), softForeground: ColorToken("#5b21b6"))
        colors[.primary] = violet
        #expect(colors.primary == violet)
        #expect(colors[.destructive] == ThemeColors.standard.destructive)
    }

    @Test func withKeepsUntouchedTokens() {
        let brand = Theme.standard.with(id: "brand") { $0.radii = $0.radii.scaled(2) }
        #expect(brand.id == "brand")
        #expect(brand.radii.lg == 24)
        #expect(brand.colors == Theme.standard.colors)
    }

    @Test(arguments: ThemeDensity.allCases)
    func densityScalesEveryStep(_ density: ThemeDensity) {
        let spacing = ThemeSpacing(density: density)
        #expect(spacing.lg == density.unit * 4)
        #expect(spacing(6) == spacing.xl)
    }

    @Test func reduceMotionDropsAnimation() {
        #expect(ThemeMotion.standard.animation(.base, reduceMotion: true) == nil)
        #expect(ThemeMotion.standard.animation(.base, reduceMotion: false) != nil)
    }

    @Test func statesDefaultToTheFeSdkValues() {
        let states = Theme.standard.states
        #expect(states.disabledOpacity == 0.45)
        #expect(states.pressedOpacity == 0.85)
        #expect(states.pressedScale == 0.97)
        #expect(states.pressedWashOpacity == 0.1)
    }

    @Test func typographyDesignSkipsMono() {
        let rounded = ThemeTypography.standard.design(.rounded)
        #expect(rounded.body.design == .rounded)
        #expect(rounded.mono.design == .monospaced)
    }

    @Test func environmentDefaultsToStandard() {
        #expect(EnvironmentValues().wow2Theme == .standard)
    }
}

extension Theme: CustomTestStringConvertible {
    public var testDescription: String { id }
}
