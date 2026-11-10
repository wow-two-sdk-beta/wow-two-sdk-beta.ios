# ChoiceField

Picks one option from a list: a row with an icon, a title, a subtitle and a trailing checkmark when selected — the radio of an iOS settings list.

Source: [ChoiceField.swift](ChoiceField.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Radio`.

## Contract

- The look comes from `ChoiceFieldAppearance.resolve(theme:isSelected:isPressed:isEnabled:)` alone.
- The trailing checkmark is `primary.base` in the semibold `label` role; its slot stays when unselected, so titles never shift.
- The row shares `ListGroupItem`'s metrics: `RowLabel` (primary-soft icon tile, `label` title, `caption` subtitle) and the row insets, at least 48 pt tall; it reports its title edge for `ListGroup`'s inset separators.
- The row paints the card fill, darkening to `muted` while pressed, so several sit in a `ListGroup` with separators.
- VoiceOver reads each row as one button with title and subtitle, and the selected trait; the checkmark is hidden.
- Disabled dims to `states.disabledOpacity`.
- Two forms: `isSelected:` + `action:` for any state, and `value:` + `selection:` that selects while the binding equals the value and sets it on tap.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.

## `ChoiceField`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The option's name. |
| `subtitle` | `LocalizedStringKey?` / `String?` | `nil` | A second, muted line. |
| `systemImage` | `String?` | `nil` | An SF Symbol in a primary-soft tile. |
| `isSelected` | `Bool` | — | Shows the checkmark (action form). |
| `action` | `@MainActor () -> Void` | — | Runs on tap (action form). |
| `value` | `Value: Hashable` | — | This row's value (binding form). |
| `selection` | `Binding<Value>` | — | The chosen value (binding form). |

## Verification

- [SelectionAppearanceTests.swift](../../../../tests/unit/presentation/SelectionAppearanceTests.swift): unselected, selected, pressed, disabled, brand restyle.
- Drawn in states by `SelectionShowcase` ([SelectionShowcase.swift](../../../../apps/showcase/SelectionShowcase.swift)).
