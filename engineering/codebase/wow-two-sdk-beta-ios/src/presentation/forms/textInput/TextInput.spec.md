# TextInput

Takes one line of text under a label, with a helper line or an error line below.

Source: [TextInput.swift](TextInput.swift). Public import: `import WoW2IosPresentation`. fe sdk: `TextInput` in `Field` chrome.

## Contract

- Every `LocalizedStringKey` init has a verbatim twin: the title takes any `StringProtocol`, optional texts take `String?`, and no localization lookup runs — for strings an app resolves itself.
- The boundary comes from `FieldAppearance.resolve(theme:isFocused:isInvalid:)`: `input` idle, `ring` focused, `destructive` invalid; 2 pt when focused or invalid.
- `error` replaces `message` and is read to VoiceOver as the field's hint.
- `error` takes a `String`, so a server message (`ApiFailure.fieldErrors["Email"]?.first?.message`) passes as is.
- `isSecure` swaps to `SecureField`.
- `.fieldChrome(isFocused:isInvalid:)` gives any raw `TextField`, `SecureField` or `TextEditor` the same boundary.

## Parameters

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `label` | `LocalizedStringKey` | — | Shown above; also the field's accessibility label. |
| `text` | `Binding<String>` | — | The value. |
| `prompt` | `LocalizedStringKey?` | `nil` | Placeholder in `subtleForeground`. |
| `message` | `LocalizedStringKey?` | `nil` | Helper line. |
| `error` | `String?` | `nil` | Error line; marks the field invalid. |
| `isSecure` | `Bool` | `false` | Masks the input. |

## Verification

- [AppearanceTests.swift](../../../../tests/unit/presentation/AppearanceTests.swift) `fieldBorderFollowsState`; rendered in the gallery.
