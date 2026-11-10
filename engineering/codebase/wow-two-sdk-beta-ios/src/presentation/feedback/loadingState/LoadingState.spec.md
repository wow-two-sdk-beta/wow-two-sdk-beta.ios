# LoadingState

Fills the space it is given with a centred spinner and an optional title and message, while a screen or a panel loads.

Source: [LoadingState.swift](LoadingState.swift). Public import: `import WoW2IosPresentation`. fe sdk: `LoadingState`.

## Contract

- The look comes from `LoadingStateAppearance.resolve(theme:tone:)` alone; its indicator is the large `SpinnerAppearance`.
- Title is `heading` in `foreground`, message `caption` in `mutedForeground`; both centred, wrapping, in Dynamic Type.
- `overMedia` draws one `scrim` card (radius `lg`) behind indicator and texts, all in `scrimForeground`.
- It takes `maxWidth` and `maxHeight` `.infinity` with an `xl` inset, so it centres in a screen, a sheet or a cell.
- VoiceOver reads the indicator, title and message as one element; the indicator is the native `ProgressView`.
- Replaces `ProgressView("Loading purchases…")` filling a list, and `ProgressView("Matching the photos…").tint(.white)` over a dark screen.
- The `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, the message `String?`.

## `LoadingState`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey?` / `StringProtocol` | `nil` | The main line. |
| `message` | `LocalizedStringKey?` / `String?` | `nil` | A secondary line. |
| `tone` | `SpinnerTone` | `.neutral` | `primary` · `neutral` · `overMedia`. |

## Verification

- [FeedbackActionsAppearanceTests.swift](../../../../tests/unit/presentation/FeedbackActionsAppearanceTests.swift): `loadingStateReadsTextTokens`, `overMediaLoadingStateUsesScrimForeground`.
- Shown in `FeedbackActionsShowcase`.
