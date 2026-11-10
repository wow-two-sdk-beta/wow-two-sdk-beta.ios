# OptionTile

Picks one option by its picture: a tile of caller-drawn art with a title, and a scrollable strip of them bound to one selection.

Source: [OptionTile.swift](OptionTile.swift), [OptionTileStrip.swift](OptionTileStrip.swift), [OptionTileVariants.swift](OptionTileVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `OptionTile`, `OptionTileGroup`.

## Contract

- The tile's look comes from `OptionTileAppearance.resolve(theme:isSelected:isPressed:isEnabled:)` alone; the strip's from `OptionTileStripAppearance.resolve(theme:)`.
- Unselected draws a `border` hairline round the art; selected draws a `primary.base` ring `sizes.ring` wide plus a checkmark badge (`primary.base` / `primary.foreground`, lifted by a `background` ring), so selection reads by shape as well as colour.
- Pressed washes the art with `primary.base` at `states.pressedWashOpacity` (the fe sdk's `bg-primary/10`) and scales it to `states.pressedScale`; Reduce Motion drops the scale and the ring and badge animations (`motion.fast`).
- The art sets the tile's size: give it a `frame`. The tile clips it to `radii.lg` and keeps it at least `sizes.controlMedium` on each side, a 44 pt target.
- The title wraps to the art's width (two lines, centred, `caption`; semibold `foreground` selected, medium `mutedForeground` otherwise) and sits `below`, `above` or `hidden`.
- VoiceOver reads each tile as one button labelled by its title, `hidden` included, with the selected trait; the art and badge are hidden.
- Disabled dims to `states.disabledOpacity`.
- `OptionTileStrip` lays the tiles in a horizontal `ScrollView` (`spacing.md` apart, unclipped), sets the binding on tap and scrolls the selected tile to the centre on appear and on every change, jumping under Reduce Motion; an optional `leading` view (an import tile) comes first.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol` (the strip's title closure returns `String`), and no localization lookup runs — for strings an app resolves itself.

## `OptionTile<Art: View>`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The label, drawn per `titlePosition`, always read by VoiceOver. |
| `isSelected` | `Bool` | — | Draws the ring and the checkmark. |
| `titlePosition` | `OptionTileTitlePosition` | `.below` | `below` · `above` · `hidden`. |
| `action` | `@MainActor () -> Void` | — | Runs on tap. |
| `art` | `@ViewBuilder` | — | The picture or drawn art; sets the tile's size. |

## `OptionTileStrip<Data, Value: Hashable, Leading: View, Art: View>`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `data` | `Data: RandomAccessCollection`, elements `Identifiable` | — | The items, in strip order. |
| `selection` | `Binding<Value>` | — | The chosen value. |
| `value` | `(Element) -> Value` | — | What choosing an item sets; `\.id` for the item's id. |
| `title` | `(Element) -> LocalizedStringKey` / `(Element) -> String` | — | Each tile's label. |
| `titlePosition` | `OptionTileTitlePosition` | `.below` | As on `OptionTile`. |
| `leading` | `@ViewBuilder` | none | A view before the items. |
| `art` | `@ViewBuilder (Element) -> Art` | — | Each tile's art. |

## Verification

- [SelectionAppearanceTests.swift](../../../../tests/unit/presentation/SelectionAppearanceTests.swift): unselected, selected, pressed, disabled, strip spacing, brand restyle.
- Drawn in states by `SelectionShowcase` ([SelectionShowcase.swift](../../../../apps/showcase/SelectionShowcase.swift)).
