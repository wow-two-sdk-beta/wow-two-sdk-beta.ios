# SelectField

Holds one setting chosen from a few options in a row: icon, title, description and the current option, opening a native menu.

Source: [SelectField.swift](SelectField.swift), [SelectOption.swift](SelectOption.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Select`.

## Contract

- The whole row is one native `Menu` holding an inline `Picker`: the menu lists every option with a checkmark on the current one, and VoiceOver and Dynamic Type stay native.
- VoiceOver reads the title as the label, the current option as the value and the description as the hint.
- The trailing current option and the up-down chevron come from `SelectFieldAppearance.resolve(theme:isEnabled:)`; disabled dims to 0.45.
- The row paints the card fill, darkening to `muted` while pressed, so it sits in a `ListGroup` with separators.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.
- `SelectOption` is shared with `SegmentedControl`; its title has the same two forms.

## `SelectField<Value: Hashable>`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The setting's name. |
| `description` | `LocalizedStringKey?` / `String?` | `nil` | What it changes. |
| `systemImage` | `String?` | `nil` | An SF Symbol in a primary-soft tile. |
| `selection` | `Binding<Value>` | — | The current value. |
| `options` | `[SelectOption<Value>]` | — | The choices, in menu order. |

## `SelectOption<Value: Hashable>`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The option's label. |
| `value` | `Value` | — | What choosing it sets; also its id. |
| `systemImage` | `String?` | `nil` | An SF Symbol beside the title. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `selectFieldReadsMutedValue`.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)); `ImageRenderer` draws the native menu as a blank placeholder, as it does the switch.
