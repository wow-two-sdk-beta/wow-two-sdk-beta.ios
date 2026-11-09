import SwiftUI
import Testing
import WoW2IosPresentation
import WoW2IosTheme

@Suite("Appearances")
struct AppearanceTests {
    private let theme = Theme.standard

    @Test func primaryButtonUsesPrimaryTone() {
        let look = ButtonAppearance.resolve(theme: theme, variant: .primary)
        #expect(look.background == theme.colors.primary.base)
        #expect(look.foreground == theme.colors.primary.foreground)
        #expect(look.border == nil)
        #expect(look.height == theme.sizes.controlMedium)
    }

    @Test func secondaryButtonIsOutlinedNeutral() {
        let look = ButtonAppearance.resolve(theme: theme, variant: .secondary)
        #expect(look.background == theme.colors.card)
        #expect(look.border == theme.colors.border)
        #expect(ButtonAppearance.resolve(theme: theme, variant: .secondary, isPressed: true).background == theme.colors.muted)
    }

    @Test func destructiveAndGhostButtons() {
        #expect(ButtonAppearance.resolve(theme: theme, variant: .destructive).background == theme.colors.destructive.base)
        let ghost = ButtonAppearance.resolve(theme: theme, variant: .ghost)
        #expect(ghost.background == nil)
        #expect(ghost.foreground == theme.colors.primary.softForeground)
    }

    @Test(arguments: ButtonVariant.allCases)
    func disabledButtonDims(_ variant: ButtonVariant) {
        #expect(ButtonAppearance.resolve(theme: theme, variant: variant, isEnabled: false).opacity < 0.5)
    }

    @Test func buttonSizesReadThemeSizes() {
        #expect(ButtonAppearance.resolve(theme: theme, variant: .primary, size: .small).height == theme.sizes.controlSmall)
        #expect(ButtonAppearance.resolve(theme: theme, variant: .primary, size: .large).height == theme.sizes.controlLarge)
    }

    /// The SDK's promise: change one token and every component that reads it follows.
    @Test func oneTokenRestylesEveryReader() {
        let violet = ColorToken("#7c3aed", "#a78bfa")
        let brand = theme.with(id: "brand") {
            $0.colors.primary.base = violet
            $0.colors.ring = violet
            $0.radii = $0.radii.scaled(2)
        }

        #expect(ButtonAppearance.resolve(theme: brand, variant: .primary).background == violet)
        #expect(FieldAppearance.resolve(theme: brand, isFocused: true).border == violet)
        #expect(CardAppearance.resolve(theme: brand, variant: .outline).radius == theme.radii.lg * 2)
        #expect(ButtonAppearance.resolve(theme: brand, variant: .secondary).background == theme.colors.card)
    }

    @Test func cardVariants() {
        let outline = CardAppearance.resolve(theme: theme, variant: .outline)
        #expect(outline.border == theme.colors.border)
        #expect(outline.shadow == nil)
        let elevated = CardAppearance.resolve(theme: theme, variant: .elevated)
        #expect(elevated.border == nil)
        #expect(elevated.shadow == theme.elevation.raised)
        #expect(CardAppearance.resolve(theme: theme, variant: .soft).background == theme.colors.muted)
    }

    @Test func fieldBorderFollowsState() {
        let idle = FieldAppearance.resolve(theme: theme)
        #expect(idle.border == theme.colors.input)
        #expect(idle.borderWidth == theme.sizes.hairline)
        #expect(FieldAppearance.resolve(theme: theme, isFocused: true).border == theme.colors.ring)
        let invalid = FieldAppearance.resolve(theme: theme, isFocused: true, isInvalid: true)
        #expect(invalid.border == theme.colors.destructive.base)
        #expect(invalid.borderWidth == theme.sizes.ring)
    }

    @Test func toastTonesCarryGlyphs() {
        #expect(ToastTone.neutral.systemImage == nil)
        #expect(ToastTone.allCases.filter { $0 != .neutral }.allSatisfy { $0.systemImage != nil && $0.tone != nil })
    }
}
