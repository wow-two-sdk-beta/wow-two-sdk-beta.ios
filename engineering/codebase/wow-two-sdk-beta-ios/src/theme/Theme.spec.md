# Theme

Holds every token a component reads; one theme supplied at the root restyles every SDK component below it.

Source: [Theme.swift](Theme.swift), [ThemeColors.swift](ThemeColors.swift), [ThemeTypography.swift](ThemeTypography.swift), [ThemeMetrics.swift](ThemeMetrics.swift), [ThemeMotion.swift](ThemeMotion.swift), [ThemeEnvironment.swift](ThemeEnvironment.swift), [ThemeContrast.swift](ThemeContrast.swift).

Public import: `import WoW2IosTheme` (or `WoW2Ios`).

## Contract

- `Theme.standard` equals the fe sdk's default theme token for token (`src/index.css`, OKLCH converted to sRGB).
- Components read `@Environment(\.wow2Theme)` only; a literal colour, font, radius or duration in a component is a defect.
- `.wow2Theme(_:)` also sets `.tint` to `colors.primary.base`, so native controls follow the brand.
- `.wow2Theme(_:tintsControls: false)` sets no tint, for an app whose `AccentColor` asset carries the brand: an explicit tint also colours iOS 26 toolbar glyphs.
- A `ColorToken` resolves light or dark from the trait environment; `resolve(_:)` gives the value for tests.
- Typography uses Dynamic Type text styles; a custom `fontName` scales `relativeTo:` its style.
- `motion.animation(…, reduceMotion: true)` is `nil`, so animated components jump under Reduce Motion.
- `scrim` / `scrimForeground` keep one value in both modes; `ThemeContrast` checks the pair with the scrim composited over white, the lightest picture.
- `ThemeContrast.failures(theme)` lists every pair below WCAG AA (text 4.5, UI 3.0) in either mode; a shipped theme lists none.

## Tokens

| Group | Members | fe sdk source |
|---|---|---|
| `colors` surfaces | `background` `foreground` `card` `cardForeground` `popover` `popoverForeground` `field` `muted` `mutedForeground` `subtleForeground` `inverse` `inverseForeground` `border` `borderStrong` `input` `ring` | `--color-{kebab-name}` |
| `colors` over media | `scrim` (black 60 %, both modes) `scrimForeground` (white) | none — iOS-only, for controls over a camera picture |
| `colors` tones | `primary` `accent` `destructive` `info` `success` `warning`, each `base` `foreground` `soft` `softForeground` | `--color-{tone}[-foreground\|-soft\|-soft-foreground]` |
| `typography` | `display` `title` `heading` `body` `label` `caption` `eyebrow` `mono` | `Heading` · `Text` · `LabelText` · `EyebrowText` · `CodeText` |
| `spacing` | `unit` × `xxs` 0.5 · `xs` 1 · `sm` 2 · `md` 3 · `lg` 4 · `xl` 6 · `xxl` 8; `spacing(n)`; `ThemeDensity` | `--spacing` density presets |
| `radii` | `sm` 4 · `md` 8 · `lg` 12 · `xl` 16 · `xxl` 24; `scaled(_:)` | `--radius-{md,lg,xl,2xl}` |
| `sizes` | `controlSmall` 32 · `controlMedium` 44 · `controlLarge` 52 · `hairline` 1 · `ring` 2 · `avatarSmall` 32 · `avatarMedium` 40 · `avatarLarge` 56 · `avatarExtraLarge` 80 | Button and `Avatar` size presets |
| `elevation` | `raised` · `overlay` | `shadow-*` |
| `motion` | `fast` 0.15 · `base` 0.2 · `slow` 0.3 · `shimmer` 1.6 · `indeterminate` 1.4; `EasingToken.out` `.in` `.standard` | `--duration-*` · `--ease-*` · `--animate-shimmer` · `ProgressBar` slide |
| `states` | `disabledOpacity` 0.45 · `pressedOpacity` 0.85 · `pressedScale` 0.97 · `pressedWashOpacity` 0.1 | `disabled:opacity-*` · `active:` · `bg-primary/10` |

## API

| Member | Meaning |
|---|---|
| `Theme.with(id:_:)` | A copy with a new id and edited tokens. |
| `RGBA.composited(over:)` | A translucent colour as seen over an opaque backdrop. |
| `ThemeColors[tone]` | Reads or writes a tone family by `Tone`. |
| `ThemeTypography.design(_:)` | Every role but `mono` in another design (`.rounded`, `.serif`). |
| `View.wow2Theme(_:tintsControls:)` | Applies the theme below this view; `tintsControls` defaults to `true`. |
| `View.themedBackground()` | Paints `background` edge to edge and sets `foreground`. |
| `ShapeStyle.token(_:)` | A token's dynamic colour for `foregroundStyle`. |

## Verification

- [ThemeTests.swift](../../tests/unit/theme/ThemeTests.swift): default tokens, contrast, hex, scheme resolution, density, motion, states, typography.
- [AppearanceTests.swift](../../tests/unit/presentation/AppearanceTests.swift) `oneTokenRestylesEveryReader`.
