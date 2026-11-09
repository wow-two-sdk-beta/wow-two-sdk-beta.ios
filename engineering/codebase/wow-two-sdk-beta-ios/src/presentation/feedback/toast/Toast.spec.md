# Toast

Shows short, self-dismissing messages one at a time from an app-owned queue.

Source: [Toast.swift](Toast.swift). Public import: `import WoW2IosPresentation`. fe sdk: `Toast`, `ToastHost`, the feedback bus.

## Contract

- `ToastCenter` is `@MainActor @Observable`: one `current` toast, the rest `pending` in order.
- `.toastHost(center)` shows `current` at the chosen edge, dismisses it after its `duration`, then shows the next.
- Each toast is announced to VoiceOver when it appears; tapping it or the "Dismiss" action removes it.
- Every tone but `neutral` shows its glyph in the tone's `softForeground`, so severity never rests on colour alone.
- Under Reduce Motion the toast fades instead of sliding.
- `.toastHost` puts the center in the environment: `@Environment(ToastCenter.self) private var toasts`.

## `ToastCenter`

| Member | Meaning |
|---|---|
| `show(_:message:tone:duration:) -> ID` | Queues a toast; it shows at once when none is on screen. |
| `show(_ toast: ToastMessage)` | Queues a built toast. |
| `dismiss(_ id: ID? = nil)` | Removes that toast, the current one by default, and brings the next forward. |
| `clear()` | Removes every toast. |

## `ToastMessage`

| Field | Type | Default | Meaning |
|---|---|---|---|
| `title` | `String` | — | The line read first. |
| `message` | `String?` | `nil` | A muted second line. |
| `tone` | `ToastTone` | `.neutral` | `neutral` · `info` · `success` · `warning` · `destructive`. |
| `duration` | `Duration` | 3 s | Time on screen. |

## Verification

- [ToastCenterTests.swift](../../../../tests/unit/presentation/ToastCenterTests.swift): queue order, dismiss, clear.
- Every tone rendered in the gallery.
