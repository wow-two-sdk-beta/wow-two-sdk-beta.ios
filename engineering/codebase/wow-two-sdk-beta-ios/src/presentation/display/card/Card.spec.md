# Card

Groups related content on one themed surface.

Source: [Card.swift](Card.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Card` (`variant`).

## Contract

- The look comes from `CardAppearance.resolve(theme:variant:)` alone.
- The card fills its container's width and aligns content leading.
- Content inherits `foreground` from the card's foreground token.

## Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `variant` | `CardVariant` | `.outline` | `outline` card fill + hairline border · `elevated` card fill + raised shadow · `soft` muted fill. |
| `padding` | `CGFloat?` | `theme.spacing.lg` | `0` for edge-to-edge media. |
| `content` | `@ViewBuilder` | — | The card's content. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `cardVariants`; rendered in the gallery.
