# WoW2SdkBetaIos migration

*Last updated: 2026-11-09*

Consumer-facing changes per tagged version, newest first. Pin `exact:`; every tag may break, and its entry here says
how to move.

## 0.0.1 — foundations and themed components

The first release. Everything is new.

| Area | Added |
|---|---|
| `WoW2IosTheme` | `Theme` (colours, typography, spacing, radii, sizes, elevation, motion), `.wow2Theme(_:)`, `.themedBackground()`, `ThemeContrast`. [Spec](src/theme/Theme.spec.md) |
| `actions` | `ThemeButtonStyle` (`.buttonStyle(.theme(.primary))`), `ActionButton`, `ButtonLabel`. [Spec](src/presentation/actions/button/Button.spec.md) |
| `display` | `Card`, `EmptyState`, `ListGroup`, `ListGroupItem`, `SectionHeader`. Specs beside each |
| `feedback` | `Toast`, `ToastCenter`, `.toastHost(_:)`, `Skeleton`, `.skeleton(_:)`, `.shimmer(_:)`. Specs beside each |
| `forms` | `TextInput`, `.fieldChrome(isFocused:isInvalid:)`, `SwitchField`, `ThemeToggleStyle` (`.toggleStyle(.theme)`). Specs beside each |
| `overlays` | `SheetHeader`. [Spec](src/presentation/overlays/sheetHeader/SheetHeader.spec.md) |
| `WoW2IosFoundation` | `AppConfig`, `ApiClient` + `ApiRequest` / `ApiResult` / `ApiFailure` / `ProblemDetails` / `FieldError`, `Log` + `MemoryLogSink`. Specs beside each |

### Adopting in an app

1. Add the package (`exact: "0.0.1"`) and link `WoW2Ios` to the app target.
2. Apply one theme at the root: `RootView().toastHost(toasts).wow2Theme(theme)`.
3. Per build configuration, set `WOW2_ENVIRONMENT` and `WOW2_API_BASE_URL` in the xcconfig, and add
   `WoW2Environment` = `$(WOW2_ENVIRONMENT)`, `WoW2ApiBaseURL` = `$(WOW2_API_BASE_URL)` to the Info.plist.
4. Build the client once: `ApiClient(config: try AppConfig.load(), headers: { … }, log: Log(category: "api"))`.

| App copy | SDK |
|---|---|
| `Logger(subsystem: "com.wowtwo.posecoach", category: "shoot")` | `Log(category: "shoot")` — the subsystem defaults to the bundle id |
| `.buttonStyle(.borderedProminent)` / `.bordered` | `.buttonStyle(.theme(.primary))` / `.theme(.secondary)` |
| `RoundedRectangle(cornerRadius: 20, style: .continuous)` fills | `Card` or `theme.radii.*` |
| `ContentUnavailableView` | `EmptyState` when the screen should carry the brand |
