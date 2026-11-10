# wow-two-sdk-beta.ios

## What is this

The ios sdk. It publishes one Swift package, `WoW2SdkBetaIos`, from `engineering/codebase/wow-two-sdk-beta-ios/`:
themed SwiftUI components and app foundations, so every WoW2 iOS app starts from the same theme, components,
API client, config and logging — the fe sdk's role for web apps.

> **Beta-forever rules**: no CHANGELOG, no PR gates, direct main releases, fix-forward when broken. CI tags `0.0.y`
> on every push to `main` that touches the package (`release-ios.yml`).

- SwiftPM reads `Package.swift` only at a git repository's root, so the manifest sits at the repo root and points
  every target into the code dir with `path:` — the one package file outside it
  ([decision](engineering/architecture/decisions/root-package-manifest.md)).
- No registry: consumers resolve the package from this repository's git tags.

## Products

| Product · module | Holds | Imports |
|---|---|---|
| `WoW2Ios` | the umbrella: re-exports the three below | all three |
| `WoW2IosFoundation` | `config/` (`AppConfig`), `http/` (`ApiClient`, envelope, problem details), `logger/` (`Log`), `localization/` (`AppLanguage`) | Foundation, Observation, os |
| `WoW2IosTheme` | `Theme` and its tokens, the `wow2Theme` environment value | SwiftUI |
| `WoW2IosPresentation` | the components | `WoW2IosTheme` |
| `WoW2IosCapture` | `shutter/` (hardware shutter modifier and policy), `photo/` (bounded import, library save, JPEG export) — never in the umbrella | SwiftUI, AVKit, Photos, ImageIO |

- Naming mirrors `WoW2.Sdk.Beta.Be` (package `WoW2SdkBetaIos`) and the fe sdk's layers (`foundation`,
  `presentation`, `foundation/themes` → its own `theme` module).
- Package identity for consumers: `wow-two-sdk-beta.ios`, taken from the repository URL.

```swift
.package(url: "https://github.com/wow-two-sdk-beta/wow-two-sdk-beta.ios", exact: "0.0.1"),
// target:
.product(name: "WoW2Ios", package: "wow-two-sdk-beta.ios"),
```

## Layout

- `src/foundation/{config,http,logger,localization}` — no SwiftUI, no theme; usable from app extensions and
  background code.
- `src/theme/` — tokens, `Theme`, environment, `ThemeContrast`.
- `src/presentation/{actions,display,feedback,forms,layout,overlays}` — components, grouped as the fe sdk groups
  them.
- `src/capture/{shutter,photo}` — camera and Photos helpers; an app imports `WoW2IosCapture` itself, so an app
  without a camera links neither framework and needs no purpose strings.
- `src/umbrella/` — `@_exported import` of the three layers.
- `apps/showcase/` — `ShowcaseView` (every component under a theme switch) and its `#Preview`s; a target, never a
  product. A family may draw its section in its own `*Showcase.swift`, placed in `ShowcaseGallery`.
- `tests/unit/{foundation,theme,presentation,capture}` mirror `src/`; `tests/support/` holds `StubTransport`.
- `MIGRATION.md` — consumer-facing changes per version, newest first.
- `engineering/` — planning, architecture, research, development rules (`engineering/engineering.md`).

## Layering

- Target dependencies enforce it at compile time: foundation and theme import nothing of ours; presentation imports
  theme only.
- A component never imports `WoW2IosFoundation`; it takes a foundation value (a server message, a status) as a
  parameter.
- A new module is a new target in `Package.swift`, re-exported by the umbrella when consumers need it.

## Theming

- `Theme` = `colors` (the fe sdk's 40 semantic tokens, camel-cased, plus `scrim` for media) · `typography` ·
  `spacing` · `radii` · `sizes` · `elevation` · `motion` · `states` (disabled and pressed).
- An app applies one theme at its root with `.wow2Theme(theme)`; it also tints native controls with `primary`.
- Components read `@Environment(\.wow2Theme)` only — never a literal colour, font, radius or duration.
- Each component resolves its look through a pure `*Appearance.resolve(theme:…)` (the fe sdk's `*.variants.ts`);
  tests pin token → component, so one token change provably restyles every reader.
- A brand theme edits tokens: `Theme.standard.with(id: "acme") { $0.colors.primary = … }`, then
  `ThemeContrast.failures(theme)` must be empty (WCAG AA in light and dark).
- Token map and contract: [`Theme.spec.md`](engineering/codebase/wow-two-sdk-beta-ios/src/theme/Theme.spec.md).

## Per-component pattern

```
presentation/actions/button/
├── ButtonVariants.swift     variant enums + ButtonAppearance.resolve
├── ThemeButtonStyle.swift   the style on SwiftUI's Button
├── ActionButton.swift       the async, self-busy button
└── Button.spec.md           one spec per component family
```

- Names mirror the fe sdk. A SwiftUI name clash becomes a style on the native control (`Button` →
  `ThemeButtonStyle`, `Toggle` → `ThemeToggleStyle`) or a distinct name (`ActionButton`, `SheetHeader`).
- Prefer a style on a native control over a custom control: it keeps VoiceOver, haptics and Dynamic Type.
- Every component: theme tokens only, Dynamic Type text styles, Reduce Motion, 44 pt targets, VoiceOver labels.
- A new component ships source, its `*.spec.md`, an entry in `ShowcaseGallery`, appearance tests and the render
  test passing.

## Casing

- Folders `camelCase` (`emptyState/`), files `PascalCase` (`EmptyState.swift`), specs `{Family}.spec.md`.
- `Package.swift` excludes every `.md` under a target automatically (`docs(in:)`); no manual exclude list.

## Versioning

- `0.0.y` forever; CI tags the next patch on each push to `main` touching `Package.swift` or the code dir.
- No release commit: the manifest carries no version, only the tag moves.
- Consumers pin `exact:`; breaking changes go in normally and land in `MIGRATION.md`.

## Develop

```bash
xcodebuild -scheme WoW2SdkBetaIos-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

- Open `Package.swift` in Xcode; the showcase previews live in `apps/showcase/ShowcaseView.swift`.
- `TEST_RUNNER_WOW2_SNAPSHOT_DIR=<dir>` before the command writes the gallery renders as PNGs for review.
- The package is iOS-only: `swift build` / `swift test` on the Mac host do not compile it.

## Working rules

- Swift 6 language mode: public value types are `Sendable`; UI state types are `@MainActor`.
- iOS 17 minimum: an iOS 18+ API needs `if #available` and a fallback.
- No third-party dependencies.
- Planning: [`backlog.md`](engineering/planning/backlog.md) and the newest
  [`version-track/`](engineering/planning/version-track/) folder; agent rules in
  [`rules.md`](engineering/development/rules.md).

## Out of scope (deliberately deferred)

- No CHANGELOG — git log, GitHub Releases and `MIGRATION.md`.
- No PR review. Push to main.
- No graduation rule. Beta-forever until the platform layer matures.
