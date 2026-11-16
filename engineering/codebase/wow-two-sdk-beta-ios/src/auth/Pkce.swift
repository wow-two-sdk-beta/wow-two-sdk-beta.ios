import CryptoKit
import Foundation
import Security

/// One RFC 7636 verifier and its S256 challenge. Keep the verifier in memory for only one authorization attempt.
public struct Pkce: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let verifier: String
    public let challenge: String

    public init() throws(OidcError) {
        self.init(verifier: try Self.randomValue())
    }

    init(verifier: String) {
        self.verifier = verifier
        self.challenge = Base64URL.encode(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    public var description: String { "Pkce(redacted)" }
    public var debugDescription: String { description }

    static func randomValue() throws(OidcError) -> String {
        var bytes = Data(count: 32)
        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else { throw .secureRandomUnavailable }
        return Base64URL.encode(bytes)
    }
}
