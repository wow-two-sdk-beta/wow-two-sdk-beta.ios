import SwiftUI
import Testing
import WoW2IosPresentation
import WoW2IosTheme

@Suite("Selection appearances")
struct SelectionAppearanceTests {
    private let theme = Theme.standard
    private let violet = ColorToken("#7c3aed", "#a78bfa")

    // MARK: OptionTile

    @Test func optionTileUnselectedDrawsHairline() {
        let look = OptionTileAppearance.resolve(theme: theme)
        #expect(look.border == theme.colors.border)
        #expect(look.borderWidth == theme.sizes.hairline)
        #expect(!look.showsCheckmark)
        #expect(look.pressedWash == nil)
        #expect(look.title == theme.colors.mutedForeground)
        #expect(look.radius == theme.radii.lg)
        #expect(look.minimumSide == theme.sizes.controlMedium)
        #expect(look.opacity == 1)
    }

    @Test func optionTileSelectedDrawsPrimaryRingAndCheckmark() {
        let look = OptionTileAppearance.resolve(theme: theme, isSelected: true)
        #expect(look.border == theme.colors.primary.base)
        #expect(look.borderWidth == theme.sizes.ring)
        #expect(look.showsCheckmark)
        #expect(look.checkmarkBackground == theme.colors.primary.base)
        #expect(look.checkmarkForeground == theme.colors.primary.foreground)
        #expect(look.title == theme.colors.foreground)
        #expect(look.titleFont.style == theme.typography.caption.style)
    }

    @Test func optionTilePressedWashesAndShrinks() {
        let look = OptionTileAppearance.resolve(theme: theme, isPressed: true)
        #expect(look.pressedWash == theme.colors.primary.base.opacity(theme.states.pressedWashOpacity))
        #expect(look.scale < 1)
        #expect(OptionTileAppearance.resolve(theme: theme).scale == 1)
    }

    @Test(arguments: [false, true])
    func optionTileDisabledDims(_ isSelected: Bool) {
        #expect(OptionTileAppearance.resolve(theme: theme, isSelected: isSelected, isEnabled: false).opacity < 0.5)
    }

    @Test func optionTileStripReadsSpacing() {
        let look = OptionTileStripAppearance.resolve(theme: theme)
        #expect(look.spacing == theme.spacing.md)
        #expect(look.verticalPadding == theme.sizes.ring)
    }

    // MARK: ChoiceField

    @Test func choiceFieldUnselectedHidesCheckmark() {
        let look = ChoiceFieldAppearance.resolve(theme: theme)
        #expect(!look.showsCheckmark)
        #expect(look.background == theme.colors.card)
        #expect(look.checkmark == theme.colors.primary.base)
        #expect(look.checkmarkFont.style == theme.typography.label.style)
    }

    @Test func choiceFieldSelectedShowsPrimaryCheckmark() {
        let look = ChoiceFieldAppearance.resolve(theme: theme, isSelected: true)
        #expect(look.showsCheckmark)
        #expect(look.checkmark == theme.colors.primary.base)
    }

    @Test func choiceFieldPressedAndDisabled() {
        #expect(ChoiceFieldAppearance.resolve(theme: theme, isPressed: true).background == theme.colors.muted)
        #expect(ChoiceFieldAppearance.resolve(theme: theme, isEnabled: false).opacity < 0.5)
    }

    // MARK: Brand

    @Test func brandRestylesSelection() {
        let brand = theme.with(id: "brand") {
            $0.colors.primary.base = violet
            $0.colors.border = violet.opacity(0.3)
            $0.radii = $0.radii.scaled(2)
            $0.sizes.ring = 3
            $0.spacing = ThemeSpacing(density: .spacious)
        }

        let tile = OptionTileAppearance.resolve(theme: brand, isSelected: true)
        #expect(tile.border == violet)
        #expect(tile.borderWidth == 3)
        #expect(tile.checkmarkBackground == violet)
        #expect(tile.radius == theme.radii.lg * 2)
        #expect(OptionTileAppearance.resolve(theme: brand).border == violet.opacity(0.3))
        #expect(OptionTileStripAppearance.resolve(theme: brand).spacing == ThemeDensity.spacious.unit * 3)
        #expect(ChoiceFieldAppearance.resolve(theme: brand, isSelected: true).checkmark == violet)
    }
}
