# AppConfig

Reads the build's environment and API base URL from the Info.plist that its xcconfig fills.

Source: [AppConfig.swift](AppConfig.swift). Public import: `import WoW2IosFoundation`. fe sdk: `foundation/config`.

## Contract

- `AppConfig.load()` reads `WoW2Environment` (`local` · `dev` · `prod`, any case) and `WoW2ApiBaseURL` (absolute `http(s)`).
- A missing or empty key throws `missing`; a value still reading `$(…)` throws `unresolved`; an unknown name throws `unknownEnvironment`; a relative or non-http URL throws `invalidURL`.
- `AppConfigKeys` renames the keys; the mobile environment convention decides the final names.
- xcconfig treats `//` as a comment: write `https:/$()/host`.

## API

| Member | Meaning |
|---|---|
| `AppConfig.load(from:keys:) throws(AppConfigError)` | Reads `Bundle.main.infoDictionary` by default. |
| `AppEnvironment.isProduction` | `true` for `prod`. |
| `ApiClient(config:…)` | A client on the configured base URL. |

## Verification

- [AppConfigTests.swift](../../../tests/unit/foundation/config/AppConfigTests.swift).
