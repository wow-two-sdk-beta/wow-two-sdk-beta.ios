import Foundation

/// The deployment an app build talks to.
public enum AppEnvironment: String, Sendable, CaseIterable, Codable {
    /// The developer's own machine.
    case local
    /// The shared development deployment.
    case dev
    /// Production.
    case prod

    public var isProduction: Bool { self == .prod }
}

/// The Info.plist keys `AppConfig` reads. An app keeps the defaults or names its own.
public struct AppConfigKeys: Sendable, Hashable {
    public var environment: String
    public var apiBaseURL: String
    public var identityAuthority: String
    public var identityClientID: String

    public init(
        environment: String = "WoW2Environment",
        apiBaseURL: String = "WoW2ApiBaseURL",
        identityAuthority: String = "WoW2IdentityAuthority",
        identityClientID: String = "WoW2IdentityClientId"
    ) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL
        self.identityAuthority = identityAuthority
        self.identityClientID = identityClientID
    }

    public static let standard = AppConfigKeys()
}

/// Why a build's configuration could not be read.
public enum AppConfigError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The key is absent from the Info.plist.
    case missing(key: String)
    /// The value still reads `$(SETTING)`: the xcconfig does not define the build setting.
    case unresolved(key: String, value: String)
    /// The environment name is none of `local`, `dev`, `prod`.
    case unknownEnvironment(String)
    /// The base URL is not an absolute `http` or `https` URL.
    case invalidURL(key: String, value: String)
    /// Identity uses an absolute HTTPS issuer with no user information, query or fragment.
    case invalidIdentityAuthority(key: String)

    public var description: String {
        switch self {
        case .missing(let key): "Info.plist has no \(key)"
        case .unresolved(let key, let value): "\(key) is \(value): the xcconfig does not define that build setting"
        case .unknownEnvironment(let name): "Unknown environment \(name); expected local, dev or prod"
        case .invalidURL(let key, let value): "\(key) is not an absolute http(s) URL: \(value)"
        case .invalidIdentityAuthority(let key): "\(key) is not an absolute HTTPS issuer"
        }
    }
}

/// The build's environment and API base URL, read from the Info.plist that the target's xcconfig fills.
///
/// ```
/// // Config/Dev.xcconfig — `//` starts a comment in xcconfig, so the scheme slashes are split by `$()`.
/// WOW2_ENVIRONMENT = dev
/// WOW2_API_BASE_URL = https:/$()/api.dev.example.com
/// ```
/// Info.plist: `WoW2Environment` = `$(WOW2_ENVIRONMENT)`, `WoW2ApiBaseURL` = `$(WOW2_API_BASE_URL)`.
public struct AppConfig: Sendable, Hashable {
    public var environment: AppEnvironment
    public var apiBaseURL: URL
    public var identityAuthority: URL?
    public var identityClientID: String?

    public init(environment: AppEnvironment, apiBaseURL: URL, identityAuthority: URL? = nil, identityClientID: String? = nil) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL
        self.identityAuthority = identityAuthority
        self.identityClientID = identityClientID
    }

    /// Reads the configuration from `info` — the main bundle's Info.plist by default.
    public static func load(
        from info: [String: Any]? = Bundle.main.infoDictionary,
        keys: AppConfigKeys = .standard
    ) throws(AppConfigError) -> AppConfig {
        let info = info ?? [:]
        let environmentName = try value(keys.environment, in: info)
        guard let environment = AppEnvironment(rawValue: environmentName.lowercased()) else {
            throw .unknownEnvironment(environmentName)
        }
        let urlText = try value(keys.apiBaseURL, in: info)
        guard let url = URL(string: urlText), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https", url.host() != nil
        else {
            throw .invalidURL(key: keys.apiBaseURL, value: urlText)
        }
        let authority = try optionalValue(keys.identityAuthority, in: info)
        let clientID = try optionalValue(keys.identityClientID, in: info)
        let issuer: URL?
        if let authority {
            guard let parsed = URL(string: authority), parsed.scheme?.lowercased() == "https",
                  parsed.host()?.isEmpty == false, parsed.user() == nil, parsed.password() == nil,
                  parsed.query() == nil, parsed.fragment() == nil
            else { throw .invalidIdentityAuthority(key: keys.identityAuthority) }
            guard clientID != nil else { throw .missing(key: keys.identityClientID) }
            issuer = parsed
        } else {
            guard clientID == nil else { throw .missing(key: keys.identityAuthority) }
            issuer = nil
        }
        return AppConfig(environment: environment, apiBaseURL: url, identityAuthority: issuer, identityClientID: clientID)
    }

    private static func value(_ key: String, in info: [String: Any]) throws(AppConfigError) -> String {
        guard let resolved = try optionalValue(key, in: info) else { throw .missing(key: key) }
        return resolved
    }

    private static func optionalValue(_ key: String, in info: [String: Any]) throws(AppConfigError) -> String? {
        guard let raw = info[key] as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.contains("$(") { throw .unresolved(key: key, value: trimmed) }
        return trimmed
    }
}
