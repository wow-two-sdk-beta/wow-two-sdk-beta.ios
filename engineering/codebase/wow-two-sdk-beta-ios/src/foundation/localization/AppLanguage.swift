import Foundation
import Observation

/// The app's runtime interface language: the person's choice, persisted, and the JSON string catalogues it reads.
///
/// Catalogues decode on first use — the base language and each language chosen so far, never all of them.
/// UI language support says nothing about speech recognition or voice availability.
@MainActor
@Observable
public final class AppLanguage {
    /// The persisted choice that follows the device's preferred languages.
    public nonisolated static let systemChoice = "system"

    /// One language the app ships, as a language picker lists it.
    public struct Choice: Identifiable, Hashable, Sendable {
        /// The BCP 47 code, which also names the catalogue file (`en`, `pt-BR`, `zh-Hans`).
        public let id: String
        /// The language's name in that language (`Deutsch`), shown in the picker.
        public let name: String

        /// A shipped language with its code and its own-language name.
        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    /// What the app ships: its languages, its catalogue files, and where the choice is stored.
    public struct Configuration: Sendable {
        /// Every shipped language, in picker order.
        public var choices: [Choice]
        /// The fallback language: its catalogue is always loaded, and a key missing elsewhere reads from it.
        public var baseCode: String
        /// The bundle that holds the catalogue files.
        public var bundle: Bundle
        /// The catalogue's resource name for a language code (`{ "locale-\($0)" }` reads `locale-de.json`).
        public var catalogueName: @Sendable (String) -> String
        /// The catalogue files' extension.
        public var catalogueExtension: String
        /// The `UserDefaults` key that keeps the choice.
        public var storageKey: String

        /// A configuration; only `choices` has no default.
        public init(
            choices: [Choice],
            baseCode: String = "en",
            bundle: Bundle = .main,
            catalogueName: @escaping @Sendable (String) -> String = { $0 },
            catalogueExtension: String = "json",
            storageKey: String = "interfaceLanguage"
        ) {
            self.choices = choices
            self.baseCode = baseCode
            self.bundle = bundle
            self.catalogueName = catalogueName
            self.catalogueExtension = catalogueExtension
            self.storageKey = storageKey
        }

        /// The supported code that best serves `identifiers`, the person's languages in order; `baseCode` when none.
        ///
        /// An exact code wins; otherwise the language and its likely script must match (`zh-TW` is Traditional, so
        /// it never reads `zh-Hans`; `uz-Cyrl` never reads Latin `uz`), and a matching region is preferred
        /// (`pt-PT` reads `pt-BR` when that is the only Portuguese).
        public func resolve(_ identifiers: [String]) -> String {
            let shipped = choices.map { (id: $0.id, tag: LanguageTag($0.id)) }
            for identifier in identifiers {
                let normalized = identifier.replacingOccurrences(of: "_", with: "-")
                if let exact = shipped.first(where: { $0.id.lowercased() == normalized.lowercased() }) { return exact.id }
                let wanted = LanguageTag(normalized)
                guard let language = wanted.language else { continue }
                let matches = shipped.filter {
                    $0.tag.language == language
                        && ($0.tag.script == nil || wanted.script == nil || $0.tag.script == wanted.script)
                }
                if let match = matches.first(where: { $0.tag.region == wanted.region }) ?? matches.first {
                    return match.id
                }
            }
            return baseCode
        }

        /// Decodes the catalogue of `code` from the bundle; empty when the file is missing or not a string map.
        public func catalog(_ code: String) -> [String: String] {
            guard let url = bundle.url(forResource: catalogueName(code), withExtension: catalogueExtension),
                  let data = try? Data(contentsOf: url),
                  let values = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
            return values
        }

        /// The code a stored choice reads: the device's languages for `systemChoice`, else the choice itself.
        func code(for choice: String) -> String {
            resolve(choice == AppLanguage.systemChoice ? Locale.preferredLanguages : [choice])
        }
    }

    /// The persisted choice: `systemChoice` or a choice's `id`. Setting it loads the catalogue before `code` changes.
    public var choice: String {
        didSet {
            defaults.set(choice, forKey: configuration.storageKey)
            let next = configuration.code(for: choice)
            // The catalogue is in place before `code` changes, so no view reads a language that is not loaded.
            if catalogs[next] == nil { catalogs[next] = configuration.catalog(next) }
            if next != code {
                code = next
                locale = Locale(identifier: next)
            }
        }
    }

    /// The language in use. Stored, since every `text(_:)` reads it; iOS relaunches the app when the system
    /// languages change, so a `systemChoice` cannot go stale while the app runs.
    public private(set) var code: String
    /// The locale of `code`, for number and date formatting.
    public private(set) var locale: Locale
    /// The configuration this language was created with.
    @ObservationIgnored public let configuration: Configuration
    @ObservationIgnored private let defaults: UserDefaults
    /// The base language and each language chosen so far; the other catalogues are never decoded.
    @ObservationIgnored private var catalogs: [String: [String: String]]

    /// Reads the stored choice (`systemChoice` when none) and decodes the base and current catalogues only.
    public init(configuration: Configuration, defaults: UserDefaults = .standard) {
        self.configuration = configuration
        self.defaults = defaults
        let choice = defaults.string(forKey: configuration.storageKey) ?? Self.systemChoice
        let code = configuration.code(for: choice)
        self.choice = choice
        self.code = code
        locale = Locale(identifier: code)
        catalogs = Dictionary(
            uniqueKeysWithValues: Set([code, configuration.baseCode]).map { ($0, configuration.catalog($0)) }
        )
    }

    /// Every shipped language, in picker order.
    public var choices: [Choice] { configuration.choices }

    /// Whether `code` is written right to left (Arabic, Hebrew, Persian, Urdu).
    public var isRightToLeft: Bool { Locale.Language(identifier: code).characterDirection == .rightToLeft }

    /// The text of `key` in the current language, then the base language, then the key itself.
    public func text(_ key: String) -> String {
        catalogs[code]?[key] ?? catalogs[configuration.baseCode]?[key] ?? key
    }

    /// `text(key)` as a format string, filled with `arguments` under the current locale.
    public func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    /// The codes whose catalogues are decoded, for tests.
    var loadedCodes: Set<String> { Set(catalogs.keys) }
}

/// A language tag expanded to its likely script and region (`zh-TW` → `zh-Hant-TW`).
private struct LanguageTag {
    let language: String?
    let script: String?
    let region: String?

    init(_ identifier: String) {
        let maximal = Locale.Language(identifier: Locale.Language(identifier: identifier).maximalIdentifier)
        language = maximal.languageCode?.identifier.lowercased()
        script = maximal.script?.identifier.lowercased()
        region = maximal.region?.identifier.lowercased()
    }
}
