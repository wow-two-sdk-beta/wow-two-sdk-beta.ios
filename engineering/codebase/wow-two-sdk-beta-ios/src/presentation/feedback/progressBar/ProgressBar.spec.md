# ProgressBar

Shows how much of a task is done, or that work of unknown length is running.

Source: [ProgressBar.swift](ProgressBar.swift). Public import: `import WoW2IosPresentation`. fe sdk: `ProgressBar`.

## Contract

- The look comes from `ProgressBarAppearance.resolve(theme:tone:size:)` alone: `muted` track, `{tone}.base` fill (`neutral` → `mutedForeground`, `danger` → `destructive`), heights `spacing.xs` · `sm` · `md`.
- `value` is clamped to `0...1`; a change animates with `motion.slow` and jumps under Reduce Motion.
- `value: nil` is indeterminate: a 35 % segment sweeps once per `motion.indeterminate` (1.4 s), read from the clock; under Reduce Motion it is a still, 40 % fill.
- VoiceOver reads `label` (default "Progress") and the whole-percent value, or "In progress" when indeterminate.

## `ProgressBar`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `value` | `Double?` | — | The share done; `nil` is indeterminate. |
| `tone` | `ProgressBarTone` | `.primary` | `primary` · `success` · `warning` · `danger` · `neutral`. |
| `size` | `ProgressBarSize` | `.medium` | `small` · `medium` · `large`. |
| `label` | `LocalizedStringKey?` / `StringProtocol` | `nil` | The accessibility name. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `progressBarTonesAndSizes`.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
