# IconButton

Runs an action from a bare SF Symbol in a themed circle — toolbars, rows and controls over a camera picture; `ToggleIconButton` is its on/off form.

Source: [IconButtonVariants.swift](IconButtonVariants.swift), [IconButtonStyle.swift](IconButtonStyle.swift), [IconButton.swift](IconButton.swift), [ToggleIconButton.swift](ToggleIconButton.swift). Public import: `import WoW2IosPresentation`. fe sdk: `IconButton`, `ToggleButton`.

## Contract

- The look comes from `IconButtonAppearance.resolve(theme:variant:size:isPressed:isEnabled:isSelected:selectedTone:isDestructive:)` alone.
- `IconButtonStyle` styles the native `Button`; it applies `.labelStyle(.iconOnly)`, so a `Label`'s title stays the VoiceOver label and `ShareLink` takes the style too.
- `ghost` has no fill (`muted` while pressed) · `soft` fills `muted` · `filled` fills `primary.base` with `primary.foreground` · `overMedia` fills `scrim` with `scrimForeground`, the pair `ThemeContrast` checks over a white picture.
- `role: .destructive` turns the `ghost` / `soft` glyph `destructive.softForeground` and the `filled` fill `destructive.base`; `overMedia` keeps the scrim pair for legibility.
- Diameters are `sizes.controlSmall` · `controlMedium` · `controlLarge`; the hit target is never under `controlMedium` (44 pt). Glyphs use `label` · `heading` · `title`, semibold, in Dynamic Type.
- Pressed dims filled fills to `states.pressedOpacity`; `.disabled` dims to `states.disabledOpacity`. The press and toggle animate at `motion.fast`, not at all under Reduce Motion.
- Selected (`ToggleIconButton` on): `ghost` / `soft` fill `{selectedTone}.soft` with `{selectedTone}.softForeground`; `filled` and `overMedia` fill `{selectedTone}.base` with `{selectedTone}.foreground`.
- `ToggleIconButton` swaps `systemImage` for `selectedSystemImage`, plays the selection haptic, and carries the `.isSelected` trait when on, which VoiceOver speaks in the device language; it sets no value text, so an app has nothing to translate.
- Replaces Pose Coach's `ControlButtonStyle` (`.icon(.overMedia)`), `FavoriteStar` (`ToggleIconButton`, `star` / `star.fill`, `.overMedia`, `selectedTone: .warning`) and icon-only toolbar buttons (`.ghost`).
- Every `LocalizedStringKey` init has a verbatim `StringProtocol` twin.

## `IconButtonStyle` · `.icon(…)`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `IconButtonVariant` | `.ghost` | `ghost` · `soft` · `filled` · `overMedia`. |
| `size` | `IconButtonSize` | `.medium` | `small` · `medium` · `large`. |
| `isSelected` | `Bool` | `false` | Draws the on state. |
| `selectedTone` | `Tone` | `.primary` | The on state's tone family. |

## `IconButton`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `systemImage` | `String` | — | The SF Symbol. |
| `label` | `LocalizedStringKey` / `StringProtocol` | — | The VoiceOver label; never shown. |
| `variant` | `IconButtonVariant` | `.ghost` | As above. |
| `size` | `IconButtonSize` | `.medium` | As above. |
| `role` | `ButtonRole?` | `nil` | `.destructive` restyles the glyph or fill. |
| `action` | `() -> Void` | — | Runs on tap. |

## `ToggleIconButton`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `isOn` | `Binding<Bool>` | — | The state; a tap toggles it. |
| `systemImage` | `String` | — | The off symbol. |
| `selectedSystemImage` | `String?` | `nil` | The on symbol; `nil` keeps `systemImage`. |
| `label` | `LocalizedStringKey` / `StringProtocol` | — | The VoiceOver label; never shown. |
| `variant` | `IconButtonVariant` | `.ghost` | As above. |
| `size` | `IconButtonSize` | `.medium` | As above. |
| `selectedTone` | `Tone` | `.primary` | The on state's tone family. |

## Verification

- [FeedbackActionsAppearanceTests.swift](../../../../tests/unit/presentation/FeedbackActionsAppearanceTests.swift): `iconButtonVariants`, `iconButtonSizesKeep44ptTarget`, `iconButtonSelectedReadsTone`, `destructiveIconButton`, `disabledIconButtonDims`, brand restyle.
- Shown in `FeedbackActionsShowcase`, `overMedia` on a dark sample surface.
