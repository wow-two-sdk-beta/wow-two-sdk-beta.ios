# codebase

*Last updated: 2026-11-09*

One Swift package, one code dir (per [`sdk-structure.md`](../../../../../conventions/development/repo/structure/sdk-structure.md)).

- [`wow-two-sdk-beta-ios/`](./wow-two-sdk-beta-ios/) — the ios sdk, the Swift package `WoW2SdkBetaIos`: `src/`
  (source and specs), `tests/` (unit + support), `apps/showcase/` (component catalogue), `MIGRATION.md`.
- Its manifest is the repo-root [`Package.swift`](../../Package.swift): SwiftPM resolves a package only from a
  repository's root, so the manifest points every target into this dir with `path:`.

Package conventions + layer rules: repo-root [`CLAUDE.md`](../../CLAUDE.md).
