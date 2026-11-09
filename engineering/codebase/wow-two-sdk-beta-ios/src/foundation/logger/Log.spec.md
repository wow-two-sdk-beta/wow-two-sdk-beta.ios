# Log

Writes category logs to the unified logging system (`os.Logger`), and optionally to a sink.

Source: [Log.swift](Log.swift), [UrlRedaction.swift](UrlRedaction.swift). Public import: `import WoW2IosFoundation`. fe sdk: `foundation/logger`.

## Contract

- `Log(category:)` defaults the subsystem to the app's bundle id.
- Messages are public by default, being written by code; `privacy: .private` redacts the whole line outside a debugger.
- Levels below `minimumLevel` are dropped before the message is built.
- A sink receives every written record; `MemoryLogSink` keeps the newest `limit` for tests and diagnostics screens.
- `log.os` is the underlying `Logger`, for per-argument privacy in interpolations.
- `UrlRedaction.path(of:)` drops query, fragment and user info before a URL reaches a log line.

## Levels

| `LogLevel` | `OSLogType` |
|---|---|
| `debug` | `.debug` |
| `info` | `.info` |
| `notice`, `warning` | `.default` |
| `error` | `.error` |
| `fault` | `.fault` |

## Verification

- [LogTests.swift](../../../tests/unit/foundation/logger/LogTests.swift).
