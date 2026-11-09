# Root package manifest

*Last updated: 2026-11-09*

> Why `Package.swift` sits at the repository root while the package's code sits in `engineering/codebase/`.

## Decision

- `Package.swift` lives at the repo root; every target sets `path:` into `engineering/codebase/wow-two-sdk-beta-ios/`.
- It is the only package file outside the code dir — the counterpart of the npm `README.md` and NuGet
  `PackageReadmeFile` exceptions.

## Why

- SwiftPM resolves a remote package only from `Package.swift` at the root of the repository a URL names; a nested
  manifest is invisible to consumers.
- A mirror repository holding only the manifest and a copy of the code would double every release; rejected.
- Moving the code to the root would break [`sdk-structure.md`](../../../../../../conventions/development/repo/structure/sdk-structure.md) for every other file; rejected.

## Consequences

- Xcode opens the package from the repo root; `xcodebuild` and CI run there, not in the code dir.
- `Package.swift` lists specs as excluded files through `docs(in:)`, so a new `.md` beside source needs no
  manifest edit.
- The release workflow's `paths:` filter watches `Package.swift` beside the code dir.
