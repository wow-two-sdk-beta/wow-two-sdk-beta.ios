# SwitchField

Holds one on/off setting in a row: icon, title, description and the themed switch.

Source: [SwitchField.swift](SwitchField.swift). Public import: `import WoW2IosPresentation`. fe sdk: `SwitchField`.

## Contract

- The row is one native `Toggle`: VoiceOver reads title, description and state as one control.
- `ThemeToggleStyle` keeps the native switch, tinted with `primary.base`, label in the label role.
- The row paints the card fill, so it sits in a `ListGroup` with separators.

## `SwitchField`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` | — | The setting's name. |
| `description` | `LocalizedStringKey?` | `nil` | What it changes. |
| `systemImage` | `String?` | `nil` | An SF Symbol in a primary-soft tile. |
| `isOn` | `Binding<Bool>` | — | The value. |

## `ThemeToggleStyle` — `.toggleStyle(.theme)`

Styles any `Toggle`: the native switch with the theme's tint, font and foreground.

## Verification

- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)); `ImageRenderer` draws the switch as a placeholder.
