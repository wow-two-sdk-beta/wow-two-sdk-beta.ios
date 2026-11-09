# wow-two-sdk-beta.ios — Engineering Rules

*Last updated: 2026-11-09*

> Working rules for agents in this repo — repo-specific deltas only. Shared rules: wow-two-ws/conventions/.
> Planning: [`backlog.md`](../planning/backlog.md) and the newest [`version-track/`](../planning/version-track/) folder.

## Gates

- Run the package tests after every change, from the repo root:
  `xcodebuild -scheme WoW2SdkBetaIos-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test`.
- Keep the build at zero warnings; Swift 6 language mode turns data races into errors.
- A missing simulator name fails the run: pick one from `xcrun simctl list devices available`.
- `swift build` / `swift test` on the Mac host cannot compile an iOS-only package; use `xcodebuild`.

## Components

- Read every colour, font, size, radius and duration from the theme; a missing value becomes a new token first.
- Resolve the look in a pure `*Appearance.resolve(theme:…)` and test it; the view only draws what it returns.
- A new component ships source, `*.spec.md`, a `ShowcaseGallery` entry and appearance tests.
- After a visual change, export the renders (`TEST_RUNNER_WOW2_SNAPSHOT_DIR`) and look at all four.
- Never name a public type after a SwiftUI type (`Button`, `Toggle`, `Section`, `Label`): consumers' files would
  stop compiling.

## Foundations

- Foundation stays free of SwiftUI and of the theme; a UI need goes to presentation.
- `ApiClient` never throws from `send`; a new failure mode is a new `ApiFailureCode` or `ApiFailureKind`.
- Log lines carry no query strings, tokens or user input unless `privacy: .private`.

## Parallel lanes

- Parallel agents edit one working tree on one branch; disjoint file sets only, no worktrees.
- `Package.swift` is shared: one lane at a time edits it.
- Commits and pushes follow the repository's git flags in wow-two-ws; CI tags `0.0.y`.
