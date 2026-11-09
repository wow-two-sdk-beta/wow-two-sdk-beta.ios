# Testing

*Last updated: 2026-11-09*

> The ios sdk's test layers, how to run them and what each proves.
> Use case — adding a test, or reading what a green run covers.

## Run

```bash
xcodebuild -scheme WoW2SdkBetaIos-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

- Swift Testing (`import Testing`) only; no XCTest.
- `TEST_RUNNER_WOW2_SNAPSHOT_DIR=<dir>` writes each gallery render to `<dir>` as PNG for a visual check.
- CI runs the same command on the newest iPhone simulator of the runner (`release-ios.yml`).

## Layers

| Target | Proves |
|---|---|
| `WoW2IosFoundationTests` | config parsing and its failures; the client's request building, envelope and problem decoding, status → kind mapping, transport errors, logging without the query; log levels and sinks |
| `WoW2IosThemeTests` | the default tokens equal the fe sdk's; WCAG AA in both modes; hex, scheme resolution, density, motion, typography helpers |
| `WoW2IosPresentationTests` | every `*Appearance` reads the right tokens; one token change restyles each reader; the toast queue; the whole gallery renders under two themes × two schemes |

## Limits

- `ImageRenderer` draws UIKit-backed controls (`TextField`, `Toggle`, `ProgressView`) as placeholders; the render test
  proves layout and no crash, not their pixels.
- No interaction tests yet (tap → busy, focus → ring); the appearance resolvers cover the state → token mapping.
- No snapshot comparison; renders are reviewed by eye when a component changes.
