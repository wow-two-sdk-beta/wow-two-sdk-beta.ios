# Architecture

*Last updated: 2026-11-09*

> How the ios sdk is layered and how its pieces meet an app.
> Use case — placing new code, or changing how the theme, the API client or the config reach an app.

## Layers

```
WoW2Ios (umbrella, @_exported)
├── WoW2IosPresentation ──► WoW2IosTheme ──► SwiftUI
├── WoW2IosTheme
└── WoW2IosFoundation ──► Foundation, os
```

| Module | fe sdk counterpart | Rule |
|---|---|---|
| `WoW2IosFoundation` | `src/foundation` (non-UI) | imports no SwiftUI and no other SDK module |
| `WoW2IosTheme` | `src/foundation/themes` | SwiftUI value types only; no views beyond the environment modifiers |
| `WoW2IosPresentation` | `src/presentation` | reads the theme from the environment; never imports foundation |
| `WoW2IosShowcase` | `apps/playground` | a target for previews and render tests; never a product |

- SwiftPM target dependencies enforce the arrows; the fe sdk needs ESLint boundaries for the same rule.
- Splitting theme from foundation keeps foundation free of SwiftUI, so widgets, intents and background tasks can
  link it alone.

## Theme flow

1. The app builds one `Theme` — `Theme.standard`, or a copy with edited tokens.
2. `.wow2Theme(theme)` at the root writes it to `EnvironmentValues.wow2Theme` and sets `.tint` to `primary`.
3. Each component reads the environment, calls its `*Appearance.resolve(theme:…)` and draws only what that
   returns.
4. `ColorToken.color` is a dynamic `UIColor`, so light and dark resolve from the trait environment, including
   `.preferredColorScheme` and sheets.

- Swapping the theme at runtime (a settings toggle) re-renders every reader; no restart, no reload.
- Fonts are Dynamic Type text styles; a custom family scales `relativeTo:` its style.

## API client flow

```
ApiRequest<T> ─► ApiClient.send ─► HttpTransport (URLSession) ─► be sdk host
                       │
                       ├─ 2xx  { data, warnings? } ─► ApiSuccess<T>
                       ├─ 204 / empty with NoContent ─► ApiSuccess<NoContent>
                       └─ non-2xx problem+json ─► ApiFailure { code, kind, status, problem }
```

- `ApiResult<T>` is `Result<ApiSuccess<T>, ApiFailure>`: callers branch, the client never throws; `data(_:)` gives a
  typed-throws shortcut.
- `ProblemDetails.errors` reads both the be sdk's `[FieldError]` array and ASP.NET's `{ field: [messages] }` map.
- Dates decode ISO 8601 with up to 7 fractional digits and an offset (`DateTimeOffset`).
- `headers` is the auth seam: an async closure the app fills from its token store.
- `HttpTransport` is the test seam: `StubTransport` answers from a script.

## Config flow

- xcconfig per build configuration → `$(WOW2_ENVIRONMENT)` / `$(WOW2_API_BASE_URL)` in Info.plist →
  `AppConfig.load()` at launch → `ApiClient(config:)`.
- `AppConfigKeys` names the Info.plist keys, so the mobile environment convention can rename them without an API
  change.
- An unsubstituted `$(…)` fails loudly (`AppConfigError.unresolved`) rather than shipping a literal.
