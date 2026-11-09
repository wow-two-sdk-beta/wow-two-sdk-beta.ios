import Foundation
import Testing
import WoW2IosFoundation

@Suite("AppConfig")
struct AppConfigTests {
    @Test func readsEnvironmentAndBaseURL() throws {
        let config = try AppConfig.load(from: ["WoW2Environment": "dev", "WoW2ApiBaseURL": "https://api.dev.example.com"])
        #expect(config.environment == .dev)
        #expect(config.apiBaseURL.absoluteString == "https://api.dev.example.com")
        #expect(!config.environment.isProduction)
    }

    @Test func readsEnvironmentCaseInsensitively() throws {
        let config = try AppConfig.load(from: ["WoW2Environment": " PROD ", "WoW2ApiBaseURL": "https://api.example.com"])
        #expect(config.environment == .prod)
    }

    @Test func honoursCustomKeys() throws {
        let keys = AppConfigKeys(environment: "Env", apiBaseURL: "Api")
        let config = try AppConfig.load(from: ["Env": "local", "Api": "http://localhost:5080"], keys: keys)
        #expect(config.environment == .local)
        #expect(config.apiBaseURL.port == 5080)
    }

    @Test func rejectsMissingKey() {
        #expect(throws: AppConfigError.missing(key: "WoW2ApiBaseURL")) {
            try AppConfig.load(from: ["WoW2Environment": "dev"])
        }
    }

    @Test func rejectsUnsubstitutedBuildSetting() {
        #expect(throws: AppConfigError.unresolved(key: "WoW2Environment", value: "$(WOW2_ENVIRONMENT)")) {
            try AppConfig.load(from: ["WoW2Environment": "$(WOW2_ENVIRONMENT)", "WoW2ApiBaseURL": "https://a.b"])
        }
    }

    @Test func rejectsUnknownEnvironment() {
        #expect(throws: AppConfigError.unknownEnvironment("staging")) {
            try AppConfig.load(from: ["WoW2Environment": "staging", "WoW2ApiBaseURL": "https://a.b"])
        }
    }

    @Test(arguments: ["https:", "api.example.com", "ftp://api.example.com"])
    func rejectsNonHttpURL(_ value: String) {
        #expect(throws: AppConfigError.invalidURL(key: "WoW2ApiBaseURL", value: value)) {
            try AppConfig.load(from: ["WoW2Environment": "dev", "WoW2ApiBaseURL": value])
        }
    }
}
