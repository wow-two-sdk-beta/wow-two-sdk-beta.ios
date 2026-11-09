# ListGroup

Groups rows into one titled, rounded section with hairline separators — an iOS settings section outside a `List`.

Source: [ListGroup.swift](ListGroup.swift), [ListGroupItem.swift](ListGroupItem.swift). Public import: `import WoW2IosPresentation`. fe sdk: `ListGroup`, `ListGroupItem`.

## Contract

- Rows paint the card fill; the border colour shows through the hairline gaps as separators, edge to edge by default.
- `separator: .inset` starts the hairline at the leftmost row title's leading edge, past the icon tile; each `RowLabel` (`ListGroupItem`, `SwitchField`, `SelectField`) reports that edge. A custom row with no `RowLabel` keeps the default `spacing.lg` inset.
- A child that paints no fill shows the border colour; use `ListGroupItem`, `SwitchField`, `SelectField` or a view with `theme.colors.card`.
- The title renders upper-case in the eyebrow role with the header trait; the footer wraps.
- `ListGroupItem` with `action` is one full-row button with a chevron, darkening to `muted` while pressed.
- Every row is at least 48 pt tall.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.

## `ListGroup`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey?` | `nil` | The section's eyebrow title. |
| `footer` | `LocalizedStringKey?` | `nil` | Guidance below the rows. |
| `separator` | `ListGroupSeparator` | `.full` | `full` edge to edge · `inset` from the row titles. |
| `content` | `@ViewBuilder` | — | The rows. |

## `ListGroupItem`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` | — | The row's label. |
| `description` | `LocalizedStringKey?` | `nil` | A second, muted line. |
| `systemImage` | `String?` | `nil` | An SF Symbol in a primary-soft tile. |
| `action` | `(@MainActor () -> Void)?` | `nil` | Makes the row a button with a chevron. |
| `trailing` | `@ViewBuilder` | none | A value or control at the end, in the muted label style. |

## Verification

- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
