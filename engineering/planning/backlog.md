# wow-two-sdk-beta.ios — Backlog

*Last updated: 2026-11-10*

Every unbuilt item, grouped; top of each group = next. Shipped work lives in [`version-track/`](version-track/).

## Features

| Feature | State | Spec |
|---|---|---|
| Theme tokens | shipped v0.1 | [Theme.spec.md](../codebase/wow-two-sdk-beta-ios/src/theme/Theme.spec.md) |
| Themed components | shipped v0.1 | specs beside each family in `src/presentation/` |
| API client | shipped v0.1 | [ApiClient.spec.md](../codebase/wow-two-sdk-beta-ios/src/foundation/http/ApiClient.spec.md) |
| Build config | shipped v0.1 | [AppConfig.spec.md](../codebase/wow-two-sdk-beta-ios/src/foundation/config/AppConfig.spec.md) |
| Logging | shipped v0.1 | [Log.spec.md](../codebase/wow-two-sdk-beta-ios/src/foundation/logger/Log.spec.md) |
| Component showcase | shipped v0.1 | — |
| Auth session | planned | — |
| Cached queries | planned | — |
| Forms and validation | planned | — |
| Localization | planned | — |
| Purchases | planned | — |

## Foundations

| Item | Type | Notes |
|---|---|---|
| Keychain token store with refresh, feeding `ApiClient.headers` | feature | pairs with the Identity domain |
| Cached async resource over `ApiClient` | feature | the fe sdk's `query`: load, refresh, stale state |
| Pagination contracts | feature | the be sdk's `PageDto<T>` / `TokenPageDto<T>` |
| Field errors onto `TextInput` by property | feature | server `FieldError` → the field's `error` |
| SDK String Catalog | feature | `Close`, `Loading`, `Dismiss` resolve from the app bundle today |
| Rename `AppConfigKeys` defaults to the mobile environment convention | engineering | once that convention lands |

## Components

| Item | Type | Notes |
|---|---|---|
| Confirm dialog | feature | the fe sdk's `confirmPopover` / `typedConfirmModal`; a themed `confirmationDialog` |
| Render-friendly `SelectField` | engineering | `ImageRenderer` draws the native `Menu` blank, so the gallery shows a placeholder row |

## Extractions

| Item | Type | Notes |
|---|---|---|
| StoreKit 2 store, purchase config and paywall | feature | Pose Coach `Purchases/*`; trigger: a second app that sells |
| Camera session and preview | feature | Pose Coach `Camera/Services/CameraSession.swift`, `CameraPreview.swift`; trigger: a second camera app |
| Nearby peer transport | feature | Pose Coach `Duo/Services/*Transport.swift` |
| Speech synthesis and recognition | feature | Pose Coach `Live/Services/CoachVoice.swift` |

## Engineering

| Item | Type | Notes |
|---|---|---|
| Interaction tests for tap → busy and focus → ring | engineering | needs a UI-test host app under `apps/` |
| Theme generator from a seed colour | feature | the fe sdk's OKLCH `generateTheme` |
| Theme registry parity with the fe sdk's `themes.json` | feature | one brand, same tokens on web and iOS |
| Snapshot comparison of gallery renders | engineering | renders are reviewed by eye today |
