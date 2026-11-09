# wow-two-sdk-beta.ios — Backlog

*Last updated: 2026-11-09*

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
| Badge and status pill | feature | the fe sdk's `Badge` |
| Banner and inline alert | feature | the fe sdk's `Alert` / `Callout` |
| Progress bar | feature | the fe sdk's `ProgressBar` |
| Segmented picker | feature | a style on the native `Picker` |
| Avatar | feature | initials fallback |
| `String` overloads for titles | feature | titles take `LocalizedStringKey` only |
| Inset separators in `ListGroup` | feature | the hairline-gap separators span the full width |

## Extractions

| Item | Type | Notes |
|---|---|---|
| StoreKit 2 store, purchase config and paywall | feature | Pose Coach `Purchases/*`; trigger: a second app that sells |
| Runtime language choice | feature | Pose Coach `Localization/Services/AppLanguage.swift` |
| Camera session, photo import and library save | feature | Pose Coach `Camera/*`; trigger: a second camera app |
| Nearby peer transport | feature | Pose Coach `Duo/Services/*Transport.swift` |
| Speech synthesis and recognition | feature | Pose Coach `Live/Services/CoachVoice.swift` |

## Engineering

| Item | Type | Notes |
|---|---|---|
| Interaction tests for tap → busy and focus → ring | engineering | needs a UI-test host app under `apps/` |
| Theme generator from a seed colour | feature | the fe sdk's OKLCH `generateTheme` |
| Theme registry parity with the fe sdk's `themes.json` | feature | one brand, same tokens on web and iOS |
| Snapshot comparison of gallery renders | engineering | renders are reviewed by eye today |
