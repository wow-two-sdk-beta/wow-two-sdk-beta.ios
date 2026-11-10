# WoW2SdkBetaIos migration

*Last updated: 2026-11-10*

Consumer-facing changes per tagged version, newest first. Pin `exact:`; every tag may break, and its entry here says
how to move.

## 0.0.3 — Pose Coach extractions

Additive: no call site written against `0.0.2` changes. Pin `exact: "0.0.3"`.

| Area | Added |
|---|---|
| `WoW2IosTheme` | `colors.scrim` · `scrimForeground` (black 60 %, white: the fill and text over media, checked by `ThemeContrast`); `states.disabledOpacity` · `pressedOpacity` · `pressedScale` · `pressedWashOpacity` (0.45 · 0.85 · 0.97 · 0.1), read by every control. [Spec](src/theme/Theme.spec.md) |
| `actions` | `IconButton`, `ToggleIconButton`, `IconButtonStyle` (`.buttonStyle(.icon(.overMedia))`); `OptionTile`, `OptionTileStrip`. Specs beside each |
| `display` | `MediaCard` (static, tappable, or a `NavigationLink(value:)`; an accessory on a media corner), `BulletList` (dot, symbol or number markers). Specs beside each |
| `feedback` | `Spinner`, `LoadingState`, `MediaPill`. Specs beside each |
| `forms` | `ChoiceField`, the radio row of a `ListGroup`. [Spec](src/presentation/forms/choiceField/ChoiceField.spec.md) |
| `layout` | New family. `ActionBar` and `.actionBar { … }`, a bottom bar over the safe area. [Spec](src/presentation/layout/actionBar/ActionBar.spec.md) |
| `WoW2IosFoundation` | `AppLanguage`: a runtime interface language over JSON catalogues, with a persisted choice. [Spec](src/foundation/localization/AppLanguage.spec.md) |
| `WoW2IosCapture` | New product, outside the umbrella. `.hardwareShutter(isEnabled:onPress:)` and `HardwareShutterPolicy`; `PhotoImport`, `ImportedPhoto`, `PhotoLibrary`, `JpegExport`, `UIImage.uprightImage(maxDimension:)`. Specs in [`shutter/`](src/capture/shutter/HardwareShutter.spec.md) and [`photo/`](src/capture/photo/Photo.spec.md) |

| Changed signature | Before → after |
|---|---|
| `Theme.init` | gains `states: ThemeStates = .standard` |
| `ThemeColors.init` | gains defaulted `scrim` and `scrimForeground` |

- `WoW2IosCapture` is its own import and its own package product: add it to the target beside `WoW2Ios`. An app that
  saves to Photos still declares `NSPhotoLibraryAddUsageDescription`.
- `.hardwareShutter` does nothing below iOS 18, where SwiftUI has no capture events.
- `AppLanguage` takes a `Configuration`: the app's languages, its bundle, the catalogue file name per code, and the
  `UserDefaults` key. An app keeps its catalogue files.
- A disabled or pressed control now reads `theme.states`; the standard values equal the literals they replace.

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
