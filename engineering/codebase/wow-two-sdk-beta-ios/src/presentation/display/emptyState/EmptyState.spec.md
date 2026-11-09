# EmptyState

Shows what a screen has when it has nothing to list: an icon, a title, guidance and the actions that fill it.

Source: [EmptyState.swift](EmptyState.swift). Public import: `import WoW2IosPresentation`. fe sdk: `EmptyState`.

## Contract

- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.
- The title carries the header trait; the icon is hidden from VoiceOver.
- The message wraps; it never truncates.
- Actions sit below the message; pass themed buttons.

## Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` | — | One line saying what is empty. |
| `systemImage` | `String` | — | An SF Symbol name. |
| `message` | `LocalizedStringKey?` | `nil` | What to do next. |
| `actions` | `@ViewBuilder` | none | The buttons that fill the screen. |

## Verification

- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
