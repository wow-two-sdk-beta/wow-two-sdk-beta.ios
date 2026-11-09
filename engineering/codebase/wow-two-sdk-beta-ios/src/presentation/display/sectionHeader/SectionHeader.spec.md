# SectionHeader

Heads a section of a screen with a title, an optional subtitle and a trailing control.

Source: [SectionHeader.swift](SectionHeader.swift). Public import: `import WoW2IosPresentation`. fe sdk: `SectionHeader`.

## Contract

- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.
- The title uses the heading role and carries the header trait.
- The trailing view aligns to the title's first baseline.

## Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` | — | The section's title. |
| `subtitle` | `LocalizedStringKey?` | `nil` | A muted caption below the title. |
| `trailing` | `@ViewBuilder` | none | An action such as "See all". |

## Verification

- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
