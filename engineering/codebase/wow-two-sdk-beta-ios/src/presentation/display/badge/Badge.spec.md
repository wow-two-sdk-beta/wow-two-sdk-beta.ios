# Badge

Marks a status or category with a non-interactive pill, optionally led by a status dot or an SF Symbol.

Source: [Badge.swift](Badge.swift), [BadgeVariants.swift](BadgeVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Badge`.

## Contract

- The look comes from `BadgeAppearance.resolve(theme:tone:variant:size:)` alone.
- `soft` fills `{tone}.soft` with `{tone}.softForeground` text · `solid` fills `{tone}.base` with `{tone}.foreground` · `outline` draws a `{tone}.base` hairline with `{tone}.softForeground` text; every text pair is one `ThemeContrast` checks.
- `neutral` uses `muted` / `foreground`, `inverse` / `inverseForeground` and a `borderStrong` outline; `danger` reads the `destructive` family.
- `showsDot` is the status pill: a dot in the tone leads the title, so state reads by shape as well as colour; `systemImage` replaces the dot.
- Heights are `spacing(5)` small and `spacing(6)` medium, grown by Dynamic Type; the pill keeps one line and its ideal width.
- VoiceOver reads the title as one static text; the dot and icon are hidden.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.

## `Badge`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The label. |
| `tone` | `BadgeTone` | `.neutral` | `neutral` · `primary` · `success` · `warning` · `danger` · `info`. |
| `variant` | `BadgeVariant` | `.soft` | `soft` · `solid` · `outline`. |
| `size` | `BadgeSize` | `.medium` | `small` · `medium`. |
| `systemImage` | `String?` | `nil` | A leading SF Symbol. |
| `showsDot` | `Bool` | `false` | Leads with a status dot. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift): `badgeVariantsReadToneSlots` per tone, sizes, brand restyle.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
