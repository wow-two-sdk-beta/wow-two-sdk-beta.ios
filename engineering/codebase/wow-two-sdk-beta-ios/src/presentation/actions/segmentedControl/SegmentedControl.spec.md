# SegmentedControl

Chooses one of a few mutually exclusive values from a row of segments, a pill sliding to the chosen one.

Source: [SegmentedControl.swift](SegmentedControl.swift). Public import: `import WoW2IosPresentation`. fe sdk: `SegmentedPicker`.

## Contract

- The look comes from `SegmentedControlAppearance.resolve(theme:isEnabled:)` alone: `muted` track, `card` thumb with a half-strength `borderStrong` hairline and the raised shadow, `foreground` on the selected segment, `mutedForeground` on the rest.
- Each segment is a native button VoiceOver reads with the selected trait and "n of count" as its hint; the row is a container.
- The pill slides with `motion.base` and jumps under Reduce Motion.
- The control is 44 pt tall; long titles shrink to 80 % before truncating.
- Disabled dims to `states.disabledOpacity`.
- Options are `SelectOption`s, so each title has a localized and a verbatim form ([SelectField.spec.md](../../forms/selectField/SelectField.spec.md)).

## `SegmentedControl<Value: Hashable>`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `selection` | `Binding<Value>` | — | The chosen value. |
| `options` | `[SelectOption<Value>]` | — | The segments, left to right; `systemImage` adds a leading SF Symbol. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `segmentedControlReadsSurfaces`.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
