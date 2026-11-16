import Foundation

public enum OidcError: Error, Equatable, Sendable {
    case invalidConfiguration
    case secureRandomUnavailable
    case invalidDiscovery
    case unexpectedIssuer
    case invalidCallback
    case authorizationDenied
    case httpStatus(Int)
    case invalidGrant
    case invalidTokenResponse
    case invalidIdentityToken
    case identityChanged
}

/// The exact issuer, client id and private redirect registered for this app and environment.
public struct OidcClientConfiguration: Sendable, Hashable {
    public let authority: URL
    public let clientID: String
    public let redirectURI: URL
    public let scopes: [String]

    public var redirectScheme: String { redirectURI.scheme! }

    public init(
        authority: URL,
        clientID: String,
        redirectURI: URL,
        scopes: [String] = ["openid", "profile", "email", "phone", "offline_access"]
    ) throws(OidcError) {
        guard Self.isSecureEndpoint(authority), authority.query() == nil,
              !clientID.isEmpty, clientID.utf8.allSatisfy({ (0x21...0x7E).contains($0) }),
              scopes.contains("openid"), Set(scopes).count == scopes.count,
              scopes.allSatisfy(Self.isScope),
              let parts = URLComponents(url: redirectURI, resolvingAgainstBaseURL: false),
              let scheme = parts.scheme,
              Self.isReverseDomain(scheme),
              parts.host == nil, parts.user == nil, parts.password == nil, parts.port == nil,
              parts.query == nil, parts.fragment == nil,
              parts.percentEncodedPath.hasPrefix("/"), !parts.percentEncodedPath.hasPrefix("//")
        else { throw .invalidConfiguration }

        self.authority = authority
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
    }

    var discoveryURL: URL {
        authority.appending(path: ".well-known/openid-configuration", directoryHint: .notDirectory)
    }

    static func isSecureEndpoint(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host()?.isEmpty == false
            && url.user() == nil && url.password() == nil && url.fragment() == nil
    }

    private static func isScope(_ scope: String) -> Bool {
        !scope.isEmpty && scope.utf8.allSatisfy { $0 == 0x21 || (0x23...0x5B).contains($0) || (0x5D...0x7E).contains($0) }
    }

    private static func isReverseDomain(_ scheme: String) -> Bool {
        let labels = scheme.lowercased().split(separator: ".", omittingEmptySubsequences: false)
        return labels.count > 1 && labels.allSatisfy { label in
            guard let first = label.utf8.first, let last = label.utf8.last else { return false }
            return isAlphaNumeric(first) && isAlphaNumeric(last)
                && label.utf8.allSatisfy { isAlphaNumeric($0) || $0 == 0x2D }
        }
    }

    private static func isAlphaNumeric(_ byte: UInt8) -> Bool {
        (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
    }
}
