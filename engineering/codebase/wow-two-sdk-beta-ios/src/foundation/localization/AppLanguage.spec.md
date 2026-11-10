# AppLanguage

Switches the app's interface language at runtime, from JSON string catalogues the app bundles.

Source: [AppLanguage.swift](AppLanguage.swift). Public import: `import WoW2IosFoundation`. fe sdk: `foundation/i18n`.

## Contract

- The app passes a `Configuration`: its `choices`, base language, bundle, catalogue file naming and `UserDefaults` key.
- `choice` persists under `storageKey`; with nothing stored it is `AppLanguage.systemChoice`, which follows
  `Locale.preferredLanguages`.
- `code` and `locale` are stored, not computed: every `text(_:)` reads them.
- Catalogues decode on first use — the base language and each language chosen, never all of them; the cache is
  `@ObservationIgnored`.
- A new choice loads its catalogue before `code` changes, so no view reads a language that is not loaded.
- `text(_:)` falls back from the current language to the base language to the key itself.
- `resolve(_:)` matches an exact code first, then language plus likely script, preferring the same region:
  `zh-CN` → `zh-Hans`, `zh-TW` → none, `uz-Cyrl` → none when only Latin `uz` ships, `pt-PT` → `pt-BR`.
- A missing or malformed catalogue reads as empty; no error reaches the UI.
- No SwiftUI: an app puts the `@Observable` instance in the environment itself.

## API

| Member | Does |
|---|---|
| `AppLanguage(configuration:defaults:)` | reads the stored choice, decodes the base and current catalogues |
| `choice` | the persisted choice: `systemChoice` or a `Choice.id` |
| `code` · `locale` | the language in use and its locale |
| `choices` | the configuration's languages, in picker order |
| `isRightToLeft` | whether `code` is written right to left |
| `text(_:)` · `format(_:_:)` | a catalogue string; a format string filled under `locale` |
| `Configuration.resolve(_:)` | the shipped code for a list of preferred languages |
| `Configuration.catalog(_:)` | one decoded catalogue, for catalogue-completeness tests |

## Verification

- [AppLanguageTests.swift](../../../tests/unit/foundation/localization/AppLanguageTests.swift).
