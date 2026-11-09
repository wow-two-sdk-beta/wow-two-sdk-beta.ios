# Skeleton

Stands in for content still loading: placeholder blocks with a shimmer sweep.

Source: [Skeleton.swift](Skeleton.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Skeleton`, `isSkeleton`.

## Contract

- `Skeleton` fills `muted`, at `theme.radii.sm` unless `radius` is set, hidden from VoiceOver.
- `.skeleton(true)` redacts a real view to placeholders, adds the shimmer, ignores taps and reads as one "Loading" element.
- The shimmer sweeps once per `theme.motion.shimmer` seconds and stays static under Reduce Motion.

## API

| Member | Meaning |
|---|---|
| `Skeleton(width:height:radius:)` | A block; `width: nil` fills the container. Height defaults to 16. |
| `View.skeleton(_ isActive: Bool)` | Shows the view as its own skeleton while active. |
| `View.shimmer(_ isActive: Bool = true)` | The sweep alone, over any shape. |

## Verification

- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
