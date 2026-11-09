# engineering

*Last updated: 2026-11-09*

The doc-bearing shell for the ios sdk (`WoW2SdkBetaIos`) — everything except the Swift package itself.

| Dir | Holds |
|---|---|
| [`planning/`](./planning/) | [`backlog.md`](./planning/backlog.md) (every unbuilt item) · [`version-track/`](./planning/version-track/) (one folder per version; newest = active, [`v0.1`](./planning/version-track/v0.1/v0.1.md)) |
| [`development/`](./development/) | [`rules.md`](./development/rules.md) — working rules for agents |
| [`architecture/`](./architecture/) | Design ([`architecture.md`](./architecture/architecture.md)) · [`testing.md`](./architecture/testing.md) · [`decisions/`](./architecture/decisions/) |
| [`research/`](./research/) | Analyses and completeness maps ([`research.md`](./research/research.md)) |
| [`codebase/`](./codebase/) | The Swift package → [`wow-two-sdk-beta-ios/`](./codebase/wow-two-sdk-beta-ios/) |

Layout follows [`sdk-structure.md`](../../../../conventions/development/repo/structure/sdk-structure.md); the root
`Package.swift` is its one exception ([decision](./architecture/decisions/root-package-manifest.md)). Package
conventions live in the repo-root [`CLAUDE.md`](../CLAUDE.md).
