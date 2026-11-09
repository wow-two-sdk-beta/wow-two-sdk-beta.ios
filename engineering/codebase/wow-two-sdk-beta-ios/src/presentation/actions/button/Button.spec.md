# Button

Styles SwiftUI's `Button` from the theme, and runs async actions from a button that shows itself busy until they return.

Source: [ButtonVariants.swift](ButtonVariants.swift), [ThemeButtonStyle.swift](ThemeButtonStyle.swift), [ActionButton.swift](ActionButton.swift).

Public import: `import WoW2IosPresentation` (or `WoW2Ios`). fe sdk: `Button` (`variant`, `tone`, `size`, `isLoading`).

## Contract

- The look comes from `ButtonAppearance.resolve(theme:variant:size:isPressed:isEnabled:)` alone.
- Busy draws the spinner over the transparent label, so width and accessible name hold; VoiceOver hears the value "Loading".
- Busy ignores taps; `ActionButton` also refuses a second run while one is pending.
- Disabled (`.disabled(true)` or the environment) dims to 0.45 opacity.
- `ActionButton` with `.destructive` passes `role: .destructive` to the native button.
- Medium height is 44 pt, Apple's minimum target.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.

## `ThemeButtonStyle` — `.buttonStyle(.theme(_:size:isBusy:isFullWidth:))`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `ButtonVariant` | `.primary` | `primary` solid brand · `secondary` outlined neutral · `destructive` solid destructive · `ghost` text only. |
| `size` | `ButtonSize` | `.medium` | Height from `theme.sizes`: small 32 · medium 44 · large 52. |
| `isBusy` | `Bool` | `false` | Spinner in place of the label; taps ignored. |
| `isFullWidth` | `Bool` | `false` | Stretches to the container's width. |

## `ActionButton`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` / `label` | `LocalizedStringKey` / `@ViewBuilder` | — | The label; `systemImage` adds a leading SF Symbol. |
| `variant`, `size`, `isFullWidth` | as above | as above | Passed to the style. |
| `isBusy` | `Bool` | `false` | Busy from outside, beside the button's own run. |
| `action` | `@MainActor () async -> Void` | — | Runs on tap; the button is busy until it returns. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift): variant tokens, pressed, disabled, sizes, one-token restyle.
- [RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift): every variant renders in the gallery.
