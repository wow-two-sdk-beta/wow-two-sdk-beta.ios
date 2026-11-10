# MediaCard

Shows an image tile — media at a fixed aspect ratio, a title and an optional caption — static, tappable or navigating, with an optional accessory over a media corner.

Source: [MediaCard.swift](MediaCard.swift), [MediaCardVariants.swift](MediaCardVariants.swift). Public import: `import WoW2IosPresentation`. fe sdk: `FeatureCard`.

## Contract

- The look comes from `MediaCardAppearance.resolve(theme:isPressed:isEnabled:)` alone.
- The media fills a `Color.clear` frame of `aspectRatio` (width ÷ height) at the card's full width, over a `muted` fill, clipped to `radii.xl` `.continuous`; size the image with `.resizable().scaledToFill()`.
- The title reads `typography.heading` in `foreground`; the caption `typography.caption` in `mutedForeground`, 2 lines with the space reserved, so cards in a grid row keep one height.
- `action:` draws the card as a native `Button` with `MediaCardButtonStyle`; `value:` as a `NavigationLink(value:)` with the same style, resolved by the stack's `navigationDestination(for:)`; neither keeps it static.
- Pressed dims the card to `states.pressedOpacity`, disabled to `states.disabledOpacity`; the change animates at `motion.fast`, and jumps under Reduce Motion.
- The accessory sits on `accessoryAlignment` of the media frame, inset `spacing.sm`, outside the button: it stays its own control and VoiceOver element. Give it a 44 pt frame (`sizes.controlMedium`) when it is a button.
- VoiceOver reads title and caption as one element (a button in the tappable forms); the media is hidden.
- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, the caption `String?`, and no localization lookup runs.

## `MediaCard`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` / `StringProtocol` | — | The tile's name. |
| `caption` | `LocalizedStringKey?` / `String?` | `nil` | A muted description under the title. |
| `aspectRatio` | `CGFloat` | `1` | The media frame's width ÷ height. |
| `accessoryAlignment` | `Alignment` | `.topTrailing` | The media corner the accessory sits on. |
| `action` | `(() -> Void)?` | `nil` | Makes the card a button; `nil` keeps it static. |
| `value` | `some Hashable` | — | The navigating form: pushed onto the enclosing `NavigationStack`. |
| `media` | `@ViewBuilder` | — | The image or placeholder filling the frame. |
| `accessory` | `@ViewBuilder` | none | A control over the media, such as a favourite star. |

## `MediaCardButtonStyle`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| — | — | — | `.buttonStyle(.mediaCard)`: the card's press and disabled dimming on any `Button` or `NavigationLink`. |

## Verification

- [DisplayLayoutAppearanceTests.swift](../../../../tests/unit/presentation/DisplayLayoutAppearanceTests.swift): `mediaCardReadsSurfaceAndTextTokens`, `mediaCardDimsWhenPressedAndMoreWhenDisabled`, `brandRestylesMediaCard`; `DisplayLayoutRenderTests` draws it in both themes and schemes.
