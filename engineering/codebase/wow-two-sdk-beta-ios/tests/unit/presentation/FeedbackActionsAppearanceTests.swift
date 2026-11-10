import SwiftUI
import Testing
import WoW2IosPresentation
import WoW2IosTheme

@Suite("Feedback and action appearances")
struct FeedbackActionsAppearanceTests {
    private let theme = Theme.standard

    private var brand: Theme {
        theme.with(id: "brand") {
            $0.colors.primary.base = ColorToken("#7c3aed", "#a78bfa")
            $0.colors.scrim = ColorToken("#000000b3")
            $0.colors.scrimForeground = ColorToken("#fefefe")
            $0.sizes.controlMedium = 48
        }
    }

    // MARK: Spinner

    @Test func spinnerTonesReadTokens() {
        #expect(SpinnerAppearance.resolve(theme: theme, tone: .primary).tint == theme.colors.primary.base)
        let neutral = SpinnerAppearance.resolve(theme: theme, tone: .neutral)
        #expect(neutral.tint == theme.colors.mutedForeground)
        #expect(neutral.background == nil)
        #expect(neutral.padding == 0)
    }

    @Test func overMediaSpinnerHasScrim() {
        let look = SpinnerAppearance.resolve(theme: theme, tone: .overMedia)
        #expect(look.tint == theme.colors.scrimForeground)
        #expect(look.labelForeground == theme.colors.scrimForeground)
        #expect(look.background == theme.colors.scrim)
        #expect(look.radius == theme.radii.lg)
        #expect(look.padding > 0)
    }

    @Test(arguments: SpinnerSize.allCases)
    func spinnerKeepsSize(_ size: SpinnerSize) {
        let look = SpinnerAppearance.resolve(theme: theme, size: size)
        #expect(look.size == size)
        #expect(look.labelFont == (size == .large ? theme.typography.label : theme.typography.caption))
    }

    // MARK: LoadingState

    @Test func loadingStateReadsTextTokens() {
        let look = LoadingStateAppearance.resolve(theme: theme)
        #expect(look.spinner.size == .large)
        #expect(look.titleForeground == theme.colors.foreground)
        #expect(look.titleFont == theme.typography.heading)
        #expect(look.messageForeground == theme.colors.mutedForeground)
        #expect(look.background == nil)
        #expect(look.padding == theme.spacing.xl)
    }

    @Test func overMediaLoadingStateUsesScrimForeground() {
        let look = LoadingStateAppearance.resolve(theme: theme, tone: .overMedia)
        #expect(look.titleForeground == theme.colors.scrimForeground)
        #expect(look.messageForeground == theme.colors.scrimForeground)
        #expect(look.background == theme.colors.scrim)
        #expect(look.spinner.background == nil)
        #expect(look.backgroundPadding > 0)
    }

    // MARK: IconButton

    @Test func iconButtonVariants() {
        let ghost = IconButtonAppearance.resolve(theme: theme, variant: .ghost)
        #expect(ghost.background == nil)
        #expect(ghost.foreground == theme.colors.foreground)
        #expect(IconButtonAppearance.resolve(theme: theme, variant: .ghost, isPressed: true).background == theme.colors.muted)
        #expect(IconButtonAppearance.resolve(theme: theme, variant: .soft).background == theme.colors.muted)
        let filled = IconButtonAppearance.resolve(theme: theme, variant: .filled)
        #expect(filled.background == theme.colors.primary.base)
        #expect(filled.foreground == theme.colors.primary.foreground)
        let media = IconButtonAppearance.resolve(theme: theme, variant: .overMedia)
        #expect(media.background == theme.colors.scrim)
        #expect(media.foreground == theme.colors.scrimForeground)
    }

    @Test(arguments: IconButtonSize.allCases)
    func iconButtonSizesKeep44ptTarget(_ size: IconButtonSize) {
        let look = IconButtonAppearance.resolve(theme: theme, size: size)
        let diameters: [IconButtonSize: CGFloat] = [
            .small: theme.sizes.controlSmall, .medium: theme.sizes.controlMedium, .large: theme.sizes.controlLarge,
        ]
        #expect(look.diameter == diameters[size])
        #expect(look.hitTarget >= theme.sizes.controlMedium)
        #expect(look.hitTarget >= look.diameter)
    }

    @Test func iconButtonSelectedReadsTone() {
        let ghost = IconButtonAppearance.resolve(theme: theme, variant: .ghost, isSelected: true)
        #expect(ghost.background == theme.colors.primary.soft)
        #expect(ghost.foreground == theme.colors.primary.softForeground)
        let star = IconButtonAppearance.resolve(theme: theme, variant: .overMedia, isSelected: true, selectedTone: .warning)
        #expect(star.background == theme.colors.warning.base)
        #expect(star.foreground == theme.colors.warning.foreground)
        let filled = IconButtonAppearance.resolve(theme: theme, variant: .filled, isSelected: true, selectedTone: .success)
        #expect(filled.background == theme.colors.success.base)
    }

    @Test func destructiveIconButton() {
        #expect(IconButtonAppearance.resolve(theme: theme, variant: .soft, isDestructive: true).foreground
            == theme.colors.destructive.softForeground)
        #expect(IconButtonAppearance.resolve(theme: theme, variant: .filled, isDestructive: true).background
            == theme.colors.destructive.base)
        #expect(IconButtonAppearance.resolve(theme: theme, variant: .overMedia, isDestructive: true).foreground
            == theme.colors.scrimForeground)
    }

    @Test(arguments: IconButtonVariant.allCases)
    func disabledIconButtonDims(_ variant: IconButtonVariant) {
        #expect(IconButtonAppearance.resolve(theme: theme, variant: variant, isEnabled: false).opacity < 0.5)
        #expect(IconButtonAppearance.resolve(theme: theme, variant: variant).opacity == 1)
    }

    // MARK: MediaPill

    @Test func mediaPillTonesReadTokens() {
        let neutral = MediaPillAppearance.resolve(theme: theme)
        #expect(neutral.background == theme.colors.scrim)
        #expect(neutral.foreground == theme.colors.scrimForeground)
        let danger = MediaPillAppearance.resolve(theme: theme, tone: .danger)
        #expect(danger.background == theme.colors.destructive.base)
        #expect(danger.foreground == theme.colors.destructive.foreground)
        #expect(MediaPillAppearance.resolve(theme: theme, tone: .success).background == theme.colors.success.base)
        #expect(MediaPillAppearance.resolve(theme: theme, tone: .warning).foreground == theme.colors.warning.foreground)
    }

    @Test func mediaPillSizes() {
        let small = MediaPillAppearance.resolve(theme: theme, size: .small)
        #expect(small.font.style == theme.typography.caption.style)
        let medium = MediaPillAppearance.resolve(theme: theme, size: .medium)
        #expect(medium.font.style == theme.typography.label.style)
        #expect(medium.font.weight == .semibold)
        #expect(medium.minHeight == theme.sizes.controlSmall)
    }

    // MARK: Brand

    @Test func brandThemeRestylesEveryReader() {
        let brand = brand
        #expect(SpinnerAppearance.resolve(theme: brand, tone: .primary).tint == brand.colors.primary.base)
        #expect(SpinnerAppearance.resolve(theme: brand, tone: .overMedia).background == brand.colors.scrim)
        #expect(LoadingStateAppearance.resolve(theme: brand, tone: .overMedia).titleForeground
            == brand.colors.scrimForeground)
        #expect(IconButtonAppearance.resolve(theme: brand, variant: .filled).background == brand.colors.primary.base)
        #expect(IconButtonAppearance.resolve(theme: brand, variant: .overMedia).background == brand.colors.scrim)
        #expect(IconButtonAppearance.resolve(theme: brand, size: .small).hitTarget == 48)
        #expect(MediaPillAppearance.resolve(theme: brand).foreground == brand.colors.scrimForeground)
        #expect(brand.colors.primary.base != theme.colors.primary.base)
        #expect(ThemeContrast.failures(brand).filter { $0.contains("scrim") } == [])
    }
}
