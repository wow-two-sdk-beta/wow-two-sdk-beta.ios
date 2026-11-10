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

    // MARK: - Components II

    @Test(arguments: BadgeTone.allCases)
    func badgeVariantsReadToneSlots(_ tone: BadgeTone) {
        let soft = BadgeAppearance.resolve(theme: theme, tone: tone, variant: .soft)
        let solid = BadgeAppearance.resolve(theme: theme, tone: tone, variant: .solid)
        let outline = BadgeAppearance.resolve(theme: theme, tone: tone, variant: .outline)
        if let family = tone.tone.map({ theme.colors[$0] }) {
            #expect(soft.background == family.soft)
            #expect(soft.foreground == family.softForeground)
            #expect(solid.background == family.base)
            #expect(solid.foreground == family.foreground)
            #expect(outline.border == family.base)
            #expect(outline.foreground == family.softForeground)
        } else {
            #expect(soft.background == theme.colors.muted)
            #expect(solid.background == theme.colors.inverse)
            #expect(solid.foreground == theme.colors.inverseForeground)
            #expect(outline.border == theme.colors.borderStrong)
        }
        #expect(outline.background == nil)
        #expect(soft.border == nil)
    }

    @Test func badgeDangerIsDestructiveAndSizesReadSpacing() {
        #expect(BadgeTone.danger.tone == .destructive)
        #expect(BadgeAppearance.resolve(theme: theme).height == theme.spacing(6))
        #expect(BadgeAppearance.resolve(theme: theme, size: .small).height == theme.spacing(5))
    }

    @Test(arguments: BannerTone.allCases)
    func bannerReadsItsTone(_ tone: BannerTone) {
        let look = BannerAppearance.resolve(theme: theme, tone: tone)
        if let family = tone.tone.map({ theme.colors[$0] }) {
            #expect(look.background == family.soft)
            #expect(look.title == family.softForeground)
            #expect(tone.systemImage != nil)
        } else {
            #expect(look.background == theme.colors.muted)
            #expect(look.message == theme.colors.mutedForeground)
            #expect(tone.systemImage == nil)
        }
        #expect(look.radius == theme.radii.lg)
    }

    @Test func progressBarTonesAndSizes() {
        #expect(ProgressBarAppearance.resolve(theme: theme).fill == theme.colors.primary.base)
        #expect(ProgressBarAppearance.resolve(theme: theme, tone: .danger).fill == theme.colors.destructive.base)
        #expect(ProgressBarAppearance.resolve(theme: theme, tone: .neutral).fill == theme.colors.mutedForeground)
        #expect(ProgressBarAppearance.resolve(theme: theme).track == theme.colors.muted)
        #expect(ProgressBarAppearance.resolve(theme: theme, size: .small).height == theme.spacing.xs)
        #expect(ProgressBarAppearance.resolve(theme: theme, size: .large).height == theme.spacing.md)
        #expect(ProgressBarAppearance.resolve(theme: theme).indeterminateDuration == theme.motion.indeterminate)
    }

    @Test func avatarSizesReadThemeSizes() {
        #expect(AvatarAppearance.resolve(theme: theme, size: .small).side == theme.sizes.avatarSmall)
        #expect(AvatarAppearance.resolve(theme: theme, size: .extraLarge).side == theme.sizes.avatarExtraLarge)
        let circle = AvatarAppearance.resolve(theme: theme, size: .large)
        #expect(circle.radius == theme.sizes.avatarLarge / 2)
        #expect(AvatarAppearance.resolve(theme: theme, size: .large, shape: .square).radius == theme.radii.lg)
        let primary = AvatarAppearance.resolve(theme: theme, tone: .primary)
        #expect(primary.background == theme.colors.primary.soft)
        #expect(primary.foreground == theme.colors.primary.softForeground)
    }

    @Test(arguments: [
        ("Ada Lovelace", "AL"), ("grace", "G"), ("Katherine G. Johnson", "KJ"), ("  ", ""), ("Jean-Luc", "JL"),
    ])
    func avatarInitials(_ name: String, _ expected: String) {
        #expect(Avatar.initials(from: name) == expected)
    }

    @Test func segmentedControlReadsSurfaces() {
        let look = SegmentedControlAppearance.resolve(theme: theme)
        #expect(look.track == theme.colors.muted)
        #expect(look.thumb == theme.colors.card)
        #expect(look.selectedForeground == theme.colors.foreground)
        #expect(look.height == theme.sizes.controlMedium)
        #expect(SegmentedControlAppearance.resolve(theme: theme, isEnabled: false).opacity < 0.5)
    }

    @Test func selectFieldReadsMutedValue() {
        let look = SelectFieldAppearance.resolve(theme: theme)
        #expect(look.value == theme.colors.mutedForeground)
        #expect(look.indicator == theme.colors.subtleForeground)
        #expect(SelectFieldAppearance.resolve(theme: theme, isEnabled: false).opacity < 0.5)
    }

    /// The second batch follows a brand edit too.
    @Test func brandRestylesComponentsII() {
        let violet = ColorToken("#7c3aed", "#a78bfa")
        let brand = theme.with(id: "brand") {
            $0.colors.primary.base = violet
            $0.sizes.avatarMedium = 44
        }
        #expect(BadgeAppearance.resolve(theme: brand, tone: .primary, variant: .solid).background == violet)
        #expect(ProgressBarAppearance.resolve(theme: brand).fill == violet)
        #expect(AvatarAppearance.resolve(theme: brand).side == 44)
    }

    @Test func stateTokensRestyleEveryControl() {
        let brand = Theme.standard.with(id: "states") {
            $0.states.disabledOpacity = 0.3
            $0.states.pressedOpacity = 0.7
            $0.states.pressedScale = 0.9
        }
        #expect(ButtonAppearance.resolve(theme: brand, variant: .primary, isEnabled: false).opacity == 0.3)
        #expect(ButtonAppearance.resolve(theme: brand, variant: .primary, isPressed: true).opacity == 0.7)
        #expect(SegmentedControlAppearance.resolve(theme: brand, isEnabled: false).opacity == 0.3)
        #expect(SelectFieldAppearance.resolve(theme: brand, isEnabled: false).opacity == 0.3)
        #expect(ChoiceFieldAppearance.resolve(theme: brand, isEnabled: false).opacity == 0.3)
        #expect(IconButtonAppearance.resolve(theme: brand, variant: .filled, isEnabled: false).opacity == 0.3)
        #expect(MediaCardAppearance.resolve(theme: brand, isPressed: true).opacity == 0.7)
        #expect(OptionTileAppearance.resolve(theme: brand, isPressed: true).scale == 0.9)
    }

    @Test func standardThemeStillClearsWcagAa() {
        #expect(ThemeContrast.failures(.standard) == [])
    }
}

