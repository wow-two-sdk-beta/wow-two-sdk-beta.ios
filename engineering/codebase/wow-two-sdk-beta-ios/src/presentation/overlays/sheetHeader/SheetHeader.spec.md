# SheetHeader

Heads a sheet with its title, an optional description and a close button.

Source: [SheetHeader.swift](SheetHeader.swift). Public import: `import WoW2IosPresentation`. fe sdk: `OverlayHeader` + `OverlayTitle`, `OverlayDescription`, `OverlayCloseButton`.

## Contract

- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.
- Close calls `onClose` when set, else the environment's `dismiss`, so a sheet needs no wiring.
- The close target is 44 pt; VoiceOver reads it as "Close".
- The title uses the title role with the header trait; the description wraps.

## Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `title` | `LocalizedStringKey` | — | The sheet's title. |
| `description` | `LocalizedStringKey?` | `nil` | A muted line below. |
| `showsClose` | `Bool` | `true` | Hides the close button for a sheet that must be answered. |
| `onClose` | `(@MainActor () -> Void)?` | `nil` | Runs instead of `dismiss`. |

## Verification

- Shown from the gallery's "Show a sheet" row in the showcase preview.
