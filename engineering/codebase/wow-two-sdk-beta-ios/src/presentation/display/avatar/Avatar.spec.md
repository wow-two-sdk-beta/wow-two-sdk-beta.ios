# Avatar

Shows a person's picture, or their initials in a tinted tile when there is none.

Source: [Avatar.swift](Avatar.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Avatar`.

## Contract

- The look comes from `AvatarAppearance.resolve(theme:size:shape:tone:)` alone; sides read `theme.sizes.avatar{Small,Medium,Large,ExtraLarge}` (32 · 40 · 56 · 80).
- Initials: the first letters of the first and last words (spaces and hyphens split), upper-cased, at most two — `Avatar.initials(from:)`; no letters show `person.fill`.
- The initials are 40 % of the side and do not grow with Dynamic Type, since the tile does not; VoiceOver reads the name with the image trait.
- `url` loads with `AsyncImage` and shows the initials while loading and on failure.
- `circle` rounds fully; `square` uses `radii.md` small and `radii.lg` otherwise.
- Tones fill `{tone}.soft` with `{tone}.softForeground`; `neutral` uses `muted` / `mutedForeground`.

## `Avatar`

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `name` | `String` | — | The person's name: initials and accessibility label. |
| `image` / `url` | `Image?` / `URL?` | `nil` | The picture, or where to load it. |
| `size` | `AvatarSize` | `.medium` | `small` · `medium` · `large` · `extraLarge`. |
| `shape` | `AvatarShape` | `.circle` | `circle` · `square`. |
| `tone` | `AvatarTone` | `.neutral` | `neutral` · `primary` · `success` · `warning` · `danger`. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift): `avatarSizesReadThemeSizes`, `avatarInitials`.
- Rendered in the gallery ([RenderTests.swift](../../../../tests/unit/presentation/RenderTests.swift)).
