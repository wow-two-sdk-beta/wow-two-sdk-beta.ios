# Vector map

*Last updated: 2026-11-10*

> Which capabilities the ios sdk can grow, where each comes from, and the trigger that pulls it.
> Use case — picking the next vector for `backlog.md`.

## From the fe sdk

| fe sdk vector | ios sdk state | Note |
|---|---|---|
| `foundation/themes` | shipped `0.0.1` | token names and default values mirrored; no OKLCH generator yet |
| `foundation/http` | shipped `0.0.1` | envelope, problem details, field errors; no pagination contracts yet |
| `foundation/config` | shipped `0.0.1` | Info.plist / xcconfig seam; the mobile environment convention may rename keys |
| `foundation/logger` | shipped `0.0.1` | `os.Logger` + sinks |
| `foundation/i18n` | backlog | String Catalog for the SDK's own strings (`Close`, `Loading`) |
| `auth` | backlog | token store in Keychain, refresh, sign-in with Apple; pairs with Identity |
| `query` | backlog | cached async loads with refresh — an `@Observable` resource over `ApiClient` |
| `formsEngine` / `validators` | backlog | field state + server `FieldError` mapping onto `TextInput` |
| `presentation/*` | 26 families shipped (`0.0.3`: spinner, loading state, icon buttons, media pill, option tiles, choice field, media card, bullet list, action bar, top bar) | next: confirm dialog |

## From Pose Coach (`ventures.pose-coach`, `apps/ios/PoseCoach`)

| Code | Generic part | Trigger |
|---|---|---|
| `Localization/Services/AppLanguage.swift` | runtime language choice + persistence | shipped `0.0.3` as `AppLanguage` in foundation |
| `Purchases/*` (`StoreKitClient`, `PurchaseStore`, `PurchaseConfiguration`) | StoreKit 2 store, bundled config, paywall | the second app that sells a subscription |
| `Camera/Services/PhotoImport.swift`, `PhotoLibrary.swift`, `CollageExport.swift`, `HardwareShutter*.swift` | photo import, library save, JPEG export, hardware shutter | shipped `0.0.3` as `WoW2IosCapture` |
| `Camera/Services/CameraSession.swift`, `CameraPreview.swift`, `CameraScreenTasks.swift`, `HeldScreenDisplayLease.swift`, `HostCaptureClock.swift` | capture session, preview, screen tasks, display lease, capture clock | the second camera app |
| `Duo/Services/DuoTransport.swift` + `MultipeerDuoTransport.swift` | nearby peer transport | the second nearby-sync feature |
| `Live/Services/CoachVoice.swift` | speech synthesis + recognition | the second voice feature |
| `os.Logger` call sites (`ShootModel`, `DuoSession`) | adopt `Log` | adopted 2026-11-10 |

- Pose Coach has no theme module and no API client: the theme and `ApiClient` are new ground, not extractions.
- Pose Coach pins `0.0.3` since 2026-11-10: every screen draws from sdk components, and its runtime language,
  shutter and photo helpers come from the sdk.
- That first adoption added `wow2Theme(_:tintsControls:)` and the one-line row title; both shipped in `0.0.2`.
- Product modules move only after Pose Coach adopts the foundations; the brief for `0.0.1` kept them out.
