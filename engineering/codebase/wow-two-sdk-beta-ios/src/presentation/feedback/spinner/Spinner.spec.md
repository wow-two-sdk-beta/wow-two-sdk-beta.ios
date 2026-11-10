# Spinner

Shows that work is under way with a themed indeterminate indicator, optionally labelled.

Source: [Spinner.swift](Spinner.swift), [SpinnerVariants.swift](SpinnerVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Spinner`.

## Contract

- The look comes from `SpinnerAppearance.resolve(theme:tone:size:)` alone.
- It styles the native `ProgressView` (`.circular`): VoiceOver reads the system's "In progress", or the label, as one element; the system draws the motion, as Apple's own indicators do under Reduce Motion.
- `primary` tints `primary.base` · `neutral` tints `mutedForeground` · `overMedia` tints `scrimForeground` on a `scrim` backdrop (radius `lg`), legible over any picture.
- Sizes map to `ControlSize` `.small` · `.regular` · `.large`; the label is `caption`, `label` at `large`, in Dynamic Type.
- Replaces `ProgressView(…)` and `ProgressView(…).tint(.white)` over a camera or a dark backdrop.
- Every `LocalizedStringKey` init has a verbatim `StringProtocol` twin.

## `Spinner`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `label` | `LocalizedStringKey` / `StringProtocol` | none | Text under the indicator; the bare init has none. |
| `tone` | `SpinnerTone` | `.neutral` | `primary` · `neutral` · `overMedia`. |
| `size` | `SpinnerSize` | `.medium` | `small` · `medium` · `large`. |

## Verification

- [FeedbackActionsAppearanceTests.swift](../../../../tests/unit/presentation/FeedbackActionsAppearanceTests.swift): `spinnerTonesReadTokens`, `overMediaSpinnerHasScrim`, brand restyle.
- Shown in `FeedbackActionsShowcase`.
