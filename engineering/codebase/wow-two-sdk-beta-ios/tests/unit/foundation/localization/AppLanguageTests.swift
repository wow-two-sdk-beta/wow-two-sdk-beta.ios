import Foundation
import Testing
@testable import WoW2IosFoundation

/// A temporary catalogue folder and an isolated defaults suite, removed when the test ends.
private final class Fixture {
    let directory: URL
    let suite: String
    let defaults: UserDefaults

    init(catalogues: [String: [String: String]]) throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (code, values) in catalogues {
            try JSONEncoder().encode(values).write(to: directory.appendingPathComponent("locale-\(code).json"))
        }
        suite = "WoW2IosFoundationTests.AppLanguage.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
    }

    var configuration: AppLanguage.Configuration {
        AppLanguage.Configuration(
            choices: AppLanguageTests.choices,
            bundle: Bundle(url: directory)!,
            catalogueName: { "locale-\($0)" },
            storageKey: "interfaceLanguage"
        )
    }

    deinit {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
    }
}

@MainActor
@Suite("AppLanguage")
struct AppLanguageTests {
    nonisolated static let choices = [
        ("en", "English"), ("uz", "O‘zbekcha"), ("ru", "Русский"), ("es", "Español"), ("fr", "Français"),
        ("de", "Deutsch"), ("pt-BR", "Português (Brasil)"), ("it", "Italiano"), ("tr", "Türkçe"),
        ("ar", "العربية"), ("hi", "हिन्दी"), ("id", "Bahasa Indonesia"), ("ja", "日本語"), ("ko", "한국어"),
        ("zh-Hans", "简体中文"),
    ].map { AppLanguage.Choice(id: $0.0, name: $0.1) }

    @Test func localeResolutionNormalizesRegionsAndRejectsUnsupportedScripts() {
        let configuration = AppLanguage.Configuration(choices: Self.choices)
        #expect(configuration.resolve(["ZH_cn"]) == "zh-Hans")
        #expect(configuration.resolve(["zh-SG"]) == "zh-Hans")
        #expect(configuration.resolve(["zh-Hans-TW"]) == "zh-Hans")
        #expect(configuration.resolve(["zh-Hant-CN", "ru-RU"]) == "ru")
        #expect(configuration.resolve(["zh-TW", "zh-HK"]) == "en")
        #expect(configuration.resolve(["uz-Cyrl-UZ", "RU-ru"]) == "ru")
        #expect(configuration.resolve(["uz-Latn-UZ"]) == "uz")
        #expect(configuration.resolve(["pt-PT"]) == "pt-BR")
        #expect(configuration.resolve(["xx-ZZ", "de-AT"]) == "de")
        #expect(configuration.resolve(["unknown"]) == "en")
    }

    @Test func aMatchingRegionWinsAmongVariantsOfOneLanguage() {
        let configuration = AppLanguage.Configuration(
            choices: [.init(id: "en-US", name: "English (US)"), .init(id: "en-GB", name: "English (UK)")],
            baseCode: "en-US"
        )
        #expect(configuration.resolve(["en-GB"]) == "en-GB")
        #expect(configuration.resolve(["en-AU"]) == "en-US")
    }

    @Test func explicitChoicePersistsAndArabicReadsRightToLeft() throws {
        let fixture = try Fixture(catalogues: ["en": ["Take photo": "Take photo"], "ar": ["Take photo": "التقط صورة"]])
        let language = AppLanguage(configuration: fixture.configuration, defaults: fixture.defaults)
        #expect(language.choice == AppLanguage.systemChoice)

        language.choice = "ar"
        #expect(language.code == "ar" && language.isRightToLeft)
        #expect(language.locale.identifier == "ar")
        #expect(AppLanguage(configuration: fixture.configuration, defaults: fixture.defaults).choice == "ar")
        #expect(language.text("Take photo") == "التقط صورة")

        language.choice = "en"
        #expect(!language.isRightToLeft)
        #expect(language.text("missing-development-key") == "missing-development-key")
    }

    @Test func catalogMissesFallBackToTheBaseLanguage() throws {
        let fixture = try Fixture(catalogues: ["en": ["a": "A", "b": "B"], "de": ["a": "Ä"]])
        let language = AppLanguage(configuration: fixture.configuration, defaults: fixture.defaults)
        language.choice = "de"
        #expect(language.text("a") == "Ä")
        #expect(language.text("b") == "B")
    }

    @Test func onlyTheBaseAndChosenCataloguesDecode() throws {
        let catalogues = Dictionary(uniqueKeysWithValues: Self.choices.map { ($0.id, ["k": $0.name]) })
        let fixture = try Fixture(catalogues: catalogues)
        fixture.defaults.set("fr", forKey: "interfaceLanguage")
        let language = AppLanguage(configuration: fixture.configuration, defaults: fixture.defaults)
        #expect(language.loadedCodes == ["en", "fr"])

        language.choice = "ja"
        #expect(language.loadedCodes == ["en", "fr", "ja"])
        #expect(language.text("k") == "日本語")
    }

    @Test func formatFillsArgumentsUnderTheLocale() throws {
        let fixture = try Fixture(catalogues: ["en": ["%d photos": "%d photos"], "de": ["%d photos": "%d Fotos"]])
        let language = AppLanguage(configuration: fixture.configuration, defaults: fixture.defaults)
        language.choice = "de"
        #expect(language.format("%d photos", 3) == "3 Fotos")
    }

    @Test func aMissingOrMalformedCatalogueReadsEmpty() throws {
        let fixture = try Fixture(catalogues: [:])
        try Data("[1, 2]".utf8).write(to: fixture.directory.appendingPathComponent("locale-en.json"))
        #expect(fixture.configuration.catalog("en").isEmpty)
        #expect(fixture.configuration.catalog("de").isEmpty)
    }
}
