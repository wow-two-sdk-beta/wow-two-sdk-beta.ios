# WoW2SdkBetaIos migration

*Last updated: 2026-11-10*

Consumer-facing changes per tagged version, newest first. Pin `exact:`; every tag may break, and its entry here says
how to move.

## 0.0.2 — second component batch

Additive: no call site written against `0.0.1` changes. Pin `exact: "0.0.2"`.

| Area | Added |
|---|---|
| `WoW2IosTheme` | `sizes.avatarSmall` · `avatarMedium` · `avatarLarge` · `avatarExtraLarge` (32 · 40 · 56 · 80); `motion.indeterminate` (1.4 s). Both inits keep defaults for the new members. [Spec](src/theme/Theme.spec.md) |
| `actions` | `SegmentedControl` + `SegmentedControlAppearance`. [Spec](src/presentation/actions/segmentedControl/SegmentedControl.spec.md) |
| `display` | `Badge` (`BadgeTone` × `BadgeVariant` soft · solid · outline, `showsDot` status pill), `Avatar` (image, URL or initials). Specs beside each |
| `feedback` | `Banner` (`BannerTone`, title, message, action, dismiss), `ProgressBar` (determinate and indeterminate). Specs beside each |
| `forms` | `SelectField` + `SelectOption` (shared with `SegmentedControl`). [Spec](src/presentation/forms/selectField/SelectField.spec.md) |
| `ListGroup` | `separator: .inset` starts the hairlines at the row titles; `.full` stays the default |
| `ListGroupItem` | The title keeps its line; a trailing value one line long shrinks to 80 % before the title wraps |
| `wow2Theme` | `tintsControls: false` applies the theme without `.tint`, for an app whose `AccentColor` asset carries the brand |
| Titles | A verbatim `String` overload beside every `LocalizedStringKey` init: `ListGroup`, `ListGroupItem`, `SwitchField`, `TextInput`, `SheetHeader`, `EmptyState`, `SectionHeader`, `ActionButton`, `ButtonLabel`. The title takes any `StringProtocol`, optional texts `String?` |

| Changed signature | Before → after |
|---|---|
| `ListGroup.init` | gains `separator: ListGroupSeparator = .full` before `content` |
| `ThemeSizes.init`, `ThemeMotion.init` | gain trailing defaulted parameters |
| `View.wow2Theme` | gains `tintsControls: Bool = true` |

- A string literal still picks the `LocalizedStringKey` init; a `String` variable now compiles and renders as is, so `Text(verbatim:)` wrappers in app code can go.
- `Toast` / `ToastCenter` already took `String`; unchanged.

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
