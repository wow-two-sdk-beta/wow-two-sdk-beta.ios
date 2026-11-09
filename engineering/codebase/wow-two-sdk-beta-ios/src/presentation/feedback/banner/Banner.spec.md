# Banner

Shows an inline alert inside a screen: severity glyph, optional title, message, optional action and optional dismiss.

Source: [Banner.swift](Banner.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Banner` / `Alert`.

## Contract

- The look comes from `BannerAppearance.resolve(theme:tone:)` alone: `{tone}.soft` fill, a 35 % `{tone}.base` hairline, `{tone}.softForeground` glyph and text; `neutral` uses `muted`, `foreground` and `mutedForeground`.
- Every tone but `neutral` shows its glyph, so severity never rests on colour alone; `danger` reads the `destructive` family.
- The action shows only when both `actionTitle` and `action` are set: an underlined text button with a 44 pt target.
- `onDismiss` adds a 44 pt close button VoiceOver names "Dismiss"; the banner never hides itself.
- VoiceOver reads title and message as one element, then the action and the close button.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.

## `Banner`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `tone` | `BannerTone` | `.info` | `neutral` · `info` · `success` · `warning` · `danger`. |
| `title` | `LocalizedStringKey?` / `String?` | `nil` | The bold first line. |
| `message` | `LocalizedStringKey` / `StringProtocol` | — | The body. |
| `actionTitle`, `action` | `LocalizedStringKey?` / `String?`, `(@MainActor () -> Void)?` | `nil` | The text button below the message. |
| `onDismiss` | `(@MainActor () -> Void)?` | `nil` | Shows the close button and runs on tap. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `bannerReadsItsTone` per tone.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
