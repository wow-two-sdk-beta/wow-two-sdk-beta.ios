import Foundation
import SwiftUI
import Testing
import WoW2IosPresentation
import WoW2IosShowcase
import WoW2IosTheme

@Suite("Display and layout appearances")
struct DisplayLayoutAppearanceTests {
    private let theme = Theme.standard

    private var brand: Theme {
        theme.with(id: "brand") {
            $0.colors.primary.base = ColorToken("#7c3aed", "#a78bfa")
            $0.colors.primary.softForeground = ColorToken("#5b21b6", "#ede9fe")
            $0.colors.muted = ColorToken("#f5f3ff", "#1e1b4b")
            $0.colors.border = ColorToken("#ddd6fe", "#4c1d95")
            $0.colors.background = ColorToken("#fdfcff", "#0c0a1d")
            $0.radii = $0.radii.scaled(2)
            $0.spacing = ThemeSpacing(density: .spacious)
            $0.typography = $0.typography.design(.rounded)
        }
    }

    // MARK: MediaCard

    @Test func mediaCardReadsSurfaceAndTextTokens() {
        let look = MediaCardAppearance.resolve(theme: theme)
        #expect(look.mediaBackground == theme.colors.muted)
        #expect(look.mediaRadius == theme.radii.xl)
        #expect(look.title == theme.colors.foreground)
        #expect(look.titleFont == theme.typography.heading)
        #expect(look.caption == theme.colors.mutedForeground)
        #expect(look.captionFont == theme.typography.caption)
        #expect(look.spacing == theme.spacing(1.5))
        #expect(look.accessoryInset == theme.spacing.sm)
        #expect(look.opacity == 1)
    }

    @Test func mediaCardDimsWhenPressedAndMoreWhenDisabled() {
        let pressed = MediaCardAppearance.resolve(theme: theme, isPressed: true)
        let disabled = MediaCardAppearance.resolve(theme: theme, isEnabled: false)
        #expect(pressed.opacity < 1)
        #expect(disabled.opacity < pressed.opacity)
        #expect(disabled.opacity < 0.5)
    }

    @Test func brandRestylesMediaCard() {
        let look = MediaCardAppearance.resolve(theme: brand)
        #expect(look.mediaRadius == theme.radii.xl * 2)
        #expect(look.mediaBackground == brand.colors.muted)
        #expect(look.titleFont.design == .rounded)
        #expect(look.accessoryInset == brand.spacing.sm)
        #expect(look != MediaCardAppearance.resolve(theme: theme))
    }

    // MARK: BulletList

    @Test(arguments: BulletListTone.allCases.filter { $0 != .neutral })
    func bulletDotReadsToneBase(_ tone: BulletListTone) throws {
        let family = theme.colors[try #require(tone.tone)]
        #expect(BulletListAppearance.resolve(theme: theme, marker: .dot, tone: tone).marker == family.base)
        #expect(BulletListAppearance.resolve(theme: theme, marker: .number, tone: tone).marker == family.softForeground)
        #expect(
            BulletListAppearance.resolve(theme: theme, marker: .symbol("checkmark"), tone: tone).marker
                == family.softForeground
        )
    }

    @Test func bulletToneMapsDangerToDestructive() {
        #expect(BulletListTone.danger.tone == .destructive)
        #expect(BulletListTone.neutral.tone == nil)
    }

    @Test(arguments: [BulletListMarker.dot, .number, .symbol("xmark")])
    func neutralBulletIsMuted(_ marker: BulletListMarker) {
        let look = BulletListAppearance.resolve(theme: theme, marker: marker, tone: .neutral)
        #expect(look.marker == theme.colors.mutedForeground)
        #expect(look.text == theme.colors.foreground)
    }

    @Test func bulletListMetricsReadTheme() {
        let look = BulletListAppearance.resolve(theme: theme)
        #expect(look.marker == theme.colors.primary.base)
        #expect(look.font == theme.typography.body)
        #expect(look.markerFont.style == theme.typography.body.style)
        #expect(look.markerFont.weight == .medium)
        #expect(look.dotSize == theme.spacing(1.5))
        #expect(look.markerSpacing == theme.spacing(2.5))
        #expect(look.itemSpacing == theme.spacing.sm)
    }

    @Test func brandRestylesBulletList() {
        let look = BulletListAppearance.resolve(theme: brand)
        #expect(look.marker == brand.colors.primary.base)
        #expect(BulletListAppearance.resolve(theme: brand, marker: .number).marker == brand.colors.primary.softForeground)
        #expect(look.itemSpacing == brand.spacing.sm)
        #expect(look.itemSpacing > BulletListAppearance.resolve(theme: theme).itemSpacing)
        #expect(look.font.design == .rounded)
    }

    // MARK: ActionBar

    @Test func actionBarVariants() {
        let page = ActionBarAppearance.resolve(theme: theme)
        #expect(page.background == theme.colors.background)
        #expect(page.border == theme.colors.border)
        #expect(page.borderWidth == theme.sizes.hairline)
        #expect(page.horizontalPadding == theme.spacing.lg)
        #expect(page.verticalPadding == theme.spacing.md)
        #expect(page.spacing == theme.spacing(2.5))
        #expect(ActionBarAppearance.resolve(theme: theme, variant: .card).background == theme.colors.card)
    }

    @Test func brandRestylesActionBar() {
        let look = ActionBarAppearance.resolve(theme: brand)
        #expect(look.background == brand.colors.background)
        #expect(look.border == brand.colors.border)
        #expect(look.horizontalPadding == brand.spacing.lg)
        #expect(look != ActionBarAppearance.resolve(theme: theme))
    }
}
