# MediaPill

Shows a short status over media — a camera viewfinder, a full-screen picture — as a pill that stays legible over any picture.

Source: [MediaPill.swift](MediaPill.swift), [MediaPillVariants.swift](MediaPillVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `BadgeOverlay`.

## Contract

- The look comes from `MediaPillAppearance.resolve(theme:tone:size:)` alone.
- `neutral` fills `scrim` with `scrimForeground` text — the pair `ThemeContrast` checks over a white picture; the other tones fill `{tone}.base` with `{tone}.foreground`, opaque, so the state also reads by colour; `danger` reads the `destructive` family.
- `small` is `caption` medium, `medium` is `label` semibold; both grow with Dynamic Type and wrap, centred, rather than truncate.
- The pill is a `Capsule` with a minimum height of `spacing(7)` small and `sizes.controlSmall` medium.
- VoiceOver reads the title as one static text; the icon is hidden.
- Replaces Pose Coach's `StatusBanner` (`small`, with a symbol) and the held-screen caption pill (`medium`).
- Every `LocalizedStringKey` init has a verbatim `StringProtocol` twin.

## `MediaPill`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The status text. |
| `systemImage` | `String?` | `nil` | A leading SF Symbol. |
| `tone` | `MediaPillTone` | `.neutral` | `neutral` · `primary` · `success` · `warning` · `danger` · `info`. |
| `size` | `MediaPillSize` | `.medium` | `small` · `medium`. |

## Verification

- [FeedbackActionsAppearanceTests.swift](../../../../tests/unit/presentation/FeedbackActionsAppearanceTests.swift): `mediaPillTonesReadTokens`, `mediaPillSizes`, brand restyle.
- Shown in `FeedbackActionsShowcase` over a dark sample surface.
