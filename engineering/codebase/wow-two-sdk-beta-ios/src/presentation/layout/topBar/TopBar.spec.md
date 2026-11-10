# TopBar

A header row for a full-screen cover or sheet with no navigation bar: a centred title, an optional subtitle under it, between a leading and a trailing slot — the top-edge counterpart of `ActionBar`.

Source: [TopBar.swift](TopBar.swift), [TopBarVariants.swift](TopBarVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `StickyLayout` (`side: 'top'`).

## Contract

- The look comes from `TopBarAppearance.resolve(theme:isInset:)` alone.
- The title is `typography.heading` in `foreground`, the subtitle `typography.caption` in `mutedForeground`, `spacing.xxs` apart; each keeps one line.
- The title stays centred on the bar's full width whatever the slots' widths: it gets the width left after the wider slot plus `spacing.sm` is reserved on both sides, and truncates before it reaches a slot.
- Controls inside one slot sit `spacing.sm` apart; a slot holds icon buttons (`IconButton`, `.buttonStyle(.icon())`) or a `Menu`, which keep their own 44 pt targets and VoiceOver labels.
- The row is at least `sizes.controlMedium` (44 pt) tall and grows with Dynamic Type.
- Padding is `spacing.lg` horizontal; `isInset: false` drops it for a container that already pads its content.
- The bar draws no background or border, so it sits on a page, a sheet or a dark media screen and follows the colour scheme.
- VoiceOver reads leading slot, title, trailing slot in that order; the title and subtitle are one element with the header trait.
- Right-to-left layout mirrors the slots.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, the subtitle `String?`, and no localization lookup runs.

## `TopBar`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The centred title. |
| `subtitle` | `LocalizedStringKey?` / `String?` | `nil` | A second line under the title. |
| `isInset` | `Bool` | `true` | `false` drops the horizontal padding. |
| `leading` | `@ViewBuilder` | `EmptyView` | The leading slot. |
| `trailing` | `@ViewBuilder` | `EmptyView` | The trailing slot. |

- Inits: both slots, `trailing:` only, `leading:` only, or neither. A bar with one slot names it (`TopBar("Edit", trailing: { … })`): a lone unlabelled closure is ambiguous.

```swift
TopBar("Person 1 of 2", isInset: false) {
    IconButton(systemImage: "xmark", label: "Close", action: close)
} trailing: {
    IconButton(systemImage: "arrow.triangle.2.circlepath.camera", label: "Switch camera", action: flip)
}
```

## Verification

- [DisplayLayoutAppearanceTests.swift](../../../../tests/unit/presentation/DisplayLayoutAppearanceTests.swift): `topBarReadsTextAndMetricTokens`, `topBarDropsPaddingWhenNotInset`, `brandRestylesTopBar`; `DisplayLayoutRenderTests` draws the container view.
