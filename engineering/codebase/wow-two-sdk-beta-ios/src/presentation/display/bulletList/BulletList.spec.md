# BulletList

Lists short text items, each led by a dot, an SF Symbol or its number, wrapped lines aligned after the marker.

Source: [BulletList.swift](BulletList.swift), [BulletListVariants.swift](BulletListVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `DescriptionList` (as a plain list).

## Contract

- The look comes from `BulletListAppearance.resolve(theme:marker:tone:)` alone.
- Text reads `typography.body` in `foreground`; items sit `spacing.sm` apart, the marker `spacing(2.5)` before its text.
- `dot` draws a `spacing(1.5)` circle in `{tone}.base`, centred in the first line; `symbol` and `number` draw in `{tone}.softForeground`, the text-contrast slot; `neutral` uses `mutedForeground` for every marker.
- `danger` reads the `destructive` family; the default tone is `primary`.
- Markers align to the first text baseline; numbers are right-aligned in a column as wide as the last number, with monospaced digits, so every item's text starts on one edge.
- VoiceOver reads each item as one element; dots and symbols are hidden, numbers are read.
- `[LocalizedStringKey]` has a verbatim twin taking any `[StringProtocol]`; no localization lookup runs.

## `BulletList`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `items` | `[LocalizedStringKey]` / `[StringProtocol]` | — | The items, in order. |
| `marker` | `BulletListMarker` | `.dot` | `dot` · `symbol(String)` · `number`. |
| `tone` | `BulletListTone` | `.primary` | `neutral` · `primary` · `success` · `warning` · `danger` · `info`. |

## Verification

- [DisplayLayoutAppearanceTests.swift](../../../../tests/unit/presentation/DisplayLayoutAppearanceTests.swift): `bulletDotReadsToneBase` per tone, `neutralBulletIsMuted` per marker, `bulletListMetricsReadTheme`, `brandRestylesBulletList`; `DisplayLayoutRenderTests` draws it.
