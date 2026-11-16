import CryptoKit
import Foundation
import Security

/// User credentials after the OIDC token response and identity claims have been validated.
public struct OidcTokens: Codable, Equatable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let accessToken: String
    public let expiresAt: Date
    public let refreshToken: String?
    public let identityToken: String?
    let originalNonce: String?

    public init(accessToken: String, expiresAt: Date, refreshToken: String? = nil, identityToken: String? = nil,
                originalNonce: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.identityToken = identityToken
        self.originalNonce = originalNonce
    }

    public var description: String { "OidcTokens(redacted)" }
    public var debugDescription: String { description }
}

public protocol TokenStore: Sendable {
    func load() async throws -> OidcTokens?
    func save(_ tokens: OidcTokens) async throws
    func remove() async throws
}

public actor MemoryTokenStore: TokenStore {
    private var tokens: OidcTokens?

    public init(tokens: OidcTokens? = nil) {
        self.tokens = tokens
    }

    public func load() -> OidcTokens? { tokens }
    public func save(_ tokens: OidcTokens) { self.tokens = tokens }
    public func remove() { tokens = nil }
}

public enum TokenStoreError: Error, Equatable, Sendable {
    case invalidService
    case malformedRecord
    case keychain(OSStatus)
}

/// Stores one token set as a non-synchronizing device-only generic password. The service identifies the
/// host app; the issuer and client id separate dev and production even inside the same service.
public actor KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    public init(service: String, configuration: OidcClientConfiguration) throws(TokenStoreError) {
        guard !service.isEmpty else { throw .invalidService }
        self.service = service
        let namespace = "\(configuration.authority.absoluteString)\u{0}\(configuration.clientID)"
        self.account = Data(SHA256.hash(data: Data(namespace.utf8))).base64EncodedString()
    }

    public func load() throws -> OidcTokens? {
        var query = lookup()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw TokenStoreError.keychain(status) }
        guard let data = result as? Data, let decoded = try? JSONDecoder().decode(OidcTokens.self, from: data)
        else { throw TokenStoreError.malformedRecord }
        return decoded
    }

    public func save(_ tokens: OidcTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let query = lookup()
        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        var status = SecItemAdd(newItem as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let update: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]
            status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        }
        guard status == errSecSuccess else { throw TokenStoreError.keychain(status) }
    }

    public func remove() throws {
        let status = SecItemDelete(lookup() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw TokenStoreError.keychain(status) }
    }

    private func lookup() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
        ]
    }
}
