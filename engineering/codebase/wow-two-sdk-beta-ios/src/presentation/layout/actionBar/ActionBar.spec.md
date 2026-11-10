# ActionBar

Pins a screen's main actions — usually one or two full-width buttons — to the bottom edge, above the home indicator.

Source: [ActionBar.swift](ActionBar.swift), [ActionBarVariants.swift](ActionBarVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `StickyLayout` (`side: 'bottom'`).

## Contract

- The look comes from `ActionBarAppearance.resolve(theme:variant:)` alone.
- `.actionBar { … }` places an `ActionBar` through `safeAreaInset(edge: .bottom, spacing: 0)`: scroll content runs under the bar and its last row stops above it.
- `page` fills `background`, `card` fills `card`; the fill runs under the home indicator, the controls stay above it.
- A `sizes.hairline` rule in `border` marks the bar's top edge; it is hidden from VoiceOver.
- Padding is `spacing.lg` horizontal and `spacing.md` vertical; controls sit `spacing(2.5)` apart, stacked (`axis: .vertical`) or side by side (`.horizontal`).
- The bar draws no controls of its own: pass `Button`s styled `.theme(…, isFullWidth: true)`, which keep 44 pt targets and their own VoiceOver labels.

## `ActionBar`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `ActionBarVariant` | `.page` | `page` page background · `card` card fill. |
| `axis` | `Axis` | `.vertical` | How the controls stack. |
| `content` | `@ViewBuilder` | — | The bar's controls. |

## `View.actionBar(variant:axis:content:)`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `ActionBarVariant` | `.page` | As `ActionBar`. |
| `axis` | `Axis` | `.vertical` | As `ActionBar`. |
| `content` | `@ViewBuilder` | — | The bar's controls. |

## Verification

- [DisplayLayoutAppearanceTests.swift](../../../../tests/unit/presentation/DisplayLayoutAppearanceTests.swift): `actionBarVariants`, `brandRestylesActionBar`; `DisplayLayoutRenderTests` draws the container view.
