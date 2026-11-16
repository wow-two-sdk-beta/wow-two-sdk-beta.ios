# JsonFileStore

Stores one Codable value in a JSON file. Public import is `WoW2IosFoundation`.

- Pass a local directory, file name and default value to `JsonFileStore(directory:fileName:defaultValue:)`.
- Use one actor instance per file to serialize loads and saves. Calling it from the main actor keeps file operations outside the view's actor.
- `load()` returns the default when the file is missing. It preserves invalid JSON beside the original file under a unique name, then restores the default at the original location.
- `save(_:)` encodes before touching the existing file and publishes with an atomic write. Read and write failures propagate.

[JsonFileStoreTests.swift](../../../tests/unit/foundation/storage/JsonFileStoreTests.swift) checks reopening, atomic replacement, preservation of invalid bytes and filename validation.
