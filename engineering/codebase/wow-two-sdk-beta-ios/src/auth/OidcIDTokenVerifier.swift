import CryptoKit
import Foundation
import Security
import WoW2IosFoundation

/// Verifies provider signatures and the claims needed to use an ID token as an account identifier.
struct OidcIDTokenVerifier: Sendable {
    enum Context: Sendable {
        case signIn(nonce: String)
        case refresh(subject: String, originalNonce: String?)
        case restore(originalNonce: String?)
    }

    private enum Algorithm: String, Decodable { case rs256 = "RS256", es256 = "ES256" }
    private static let clockSkew: TimeInterval = 60
    private let provider: OidcProvider
    private let clientID: String
    private let transport: any HttpTransport
    private let time: @Sendable () -> Date

    init(provider: OidcProvider, clientID: String, transport: any HttpTransport, time: @escaping @Sendable () -> Date) {
        self.provider = provider
        self.clientID = clientID
        self.transport = transport
        self.time = time
    }

    func verify(_ token: String, accessToken: String? = nil, context: Context) async throws -> OidcPrincipal {
        guard token.utf8.count <= 24_576 else { throw OidcError.invalidIdentityToken }
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3,
              let headerData = Base64URL.decode(segments[0]),
              let claimsData = Base64URL.decode(segments[1]),
              let signature = Base64URL.decode(segments[2]),
              let header = try? JSONDecoder().decode(Header.self, from: headerData),
              header.critical?.isEmpty != false, header.encodedPayload != false,
              header.type == nil || header.type?.lowercased() == "jwt",
              provider.signingAlgorithms?.contains(header.algorithm.rawValue) != false,
              let claims = try? JSONDecoder().decode(Claims.self, from: claimsData),
              claims.issuer == provider.issuer.absoluteString,
              claims.audience.values == [clientID],
              claims.authorizedParty == nil || claims.authorizedParty == clientID,
              !claims.subject.isEmpty, claims.subject.utf8.count <= 255
        else { throw OidcError.invalidIdentityToken }

        let message = Data("\(segments[0]).\(segments[1])".utf8)
        let matching = try await keys().filter { $0.supports(header) }
        guard matching.count == 1, let key = matching.first,
              key.verifies(signature: signature, message: message, using: header.algorithm)
        else { throw OidcError.invalidIdentityToken }

        let now = time().timeIntervalSince1970
        guard claims.issuedAt.isFinite, claims.expires.isFinite,
              claims.issuedAt >= 0, claims.issuedAt <= now + Self.clockSkew, claims.expires > claims.issuedAt,
              claims.notBefore.map({ $0.isFinite && $0 <= now + Self.clockSkew }) != false
        else { throw OidcError.invalidIdentityToken }

        switch context {
        case let .signIn(nonce):
            guard claims.expires > now - Self.clockSkew, claims.nonce == nonce else { throw OidcError.invalidIdentityToken }
        case let .refresh(subject, originalNonce):
            guard claims.subject == subject else { throw OidcError.identityChanged }
            guard claims.expires > now - Self.clockSkew, claims.nonce == nil || claims.nonce == originalNonce
            else { throw OidcError.invalidIdentityToken }
        case let .restore(originalNonce):
            // A historical ID token can identify a stored session after its own expiry. Its access token
            // can only be used while that separate expiry is valid, or after a successful refresh.
            guard claims.nonce == nil || claims.nonce == originalNonce else { throw OidcError.invalidIdentityToken }
        }

        if let hash = claims.accessTokenHash, let accessToken {
            let digest = SHA256.hash(data: Data(accessToken.utf8))
            guard hash == Base64URL.encode(Data(digest.prefix(16))) else { throw OidcError.invalidIdentityToken }
        }

        return OidcPrincipal(subject: claims.subject, name: claims.name, email: claims.email, phoneNumber: claims.phoneNumber)
    }

    private func keys() async throws -> [JWK] {
        var request = URLRequest(url: provider.jwksURI)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else { throw OidcError.httpStatus(response.statusCode) }
        guard data.count <= 1_048_576, let document = try? JSONDecoder().decode(JWKSet.self, from: data),
              document.keys.count <= 128 else { throw OidcError.invalidIdentityToken }
        return document.keys
    }

    private struct Header: Decodable {
        let algorithm: Algorithm
        let keyID: String?
        let critical: [String]?
        let encodedPayload: Bool?
        let type: String?

        enum CodingKeys: String, CodingKey {
            case algorithm = "alg", keyID = "kid", critical = "crit", encodedPayload = "b64", type = "typ"
        }
    }

    private struct Claims: Decodable {
        let issuer: String
        let subject: String
        let audience: Audience
        let authorizedParty: String?
        let issuedAt: TimeInterval
        let expires: TimeInterval
        let notBefore: TimeInterval?
        let nonce: String?
        let accessTokenHash: String?
        let name: String?
        let email: String?
        let phoneNumber: String?

        enum CodingKeys: String, CodingKey {
            case issuer = "iss", subject = "sub", audience = "aud", authorizedParty = "azp"
            case issuedAt = "iat", expires = "exp", notBefore = "nbf", nonce, accessTokenHash = "at_hash"
            case name, email, phoneNumber = "phone_number"
        }
    }

    private struct Audience: Decodable {
        let values: [String]

        init(from decoder: any Decoder) throws {
            let field = try decoder.singleValueContainer()
            if let string = try? field.decode(String.self) {
                values = [string]
            } else {
                values = try field.decode([String].self)
            }
        }
    }

    private struct JWKSet: Decodable { let keys: [JWK] }

    private struct JWK: Decodable {
        let keyType: String
        let keyID: String?
        let algorithm: String?
        let use: String?
        let operations: [String]?
        let curve: String?
        let x: String?
        let y: String?
        let modulus: String?
        let exponent: String?

        enum CodingKeys: String, CodingKey {
            case keyType = "kty", keyID = "kid", algorithm = "alg", use, operations = "key_ops"
            case curve = "crv", x, y, modulus = "n", exponent = "e"
        }

        func supports(_ header: Header) -> Bool {
            (header.keyID == nil || header.keyID == keyID)
                && (algorithm == nil || algorithm == header.algorithm.rawValue)
                && (use == nil || use == "sig")
                && operations?.contains("verify") != false
                && keyType == (header.algorithm == .rs256 ? "RSA" : "EC")
        }

        func verifies(signature: Data, message: Data, using algorithm: Algorithm) -> Bool {
            switch algorithm {
            case .es256:
                guard curve == "P-256", let x = x.flatMap(Base64URL.decode), let y = y.flatMap(Base64URL.decode),
                      x.count == 32, y.count == 32,
                      let key = try? P256.Signing.PublicKey(x963Representation: Data([4]) + x + y),
                      let proof = try? P256.Signing.ECDSASignature(rawRepresentation: signature)
                else { return false }
                return key.isValidSignature(proof, for: message)
            case .rs256:
                guard let modulus = modulus.flatMap(Base64URL.decode), let exponent = exponent.flatMap(Base64URL.decode),
                      (256...1024).contains(modulus.count), modulus.first.map({ $0 >= 128 }) == true,
                      signature.count == modulus.count, (1...4).contains(exponent.count),
                      let last = exponent.last, last & 1 == 1, exponent.reduce(UInt64(0), { ($0 << 8) | UInt64($1) }) > 1,
                      exponent.first != 0
                else { return false }
                let publicKey = DER.element(0x30, DER.unsignedInteger(modulus) + DER.unsignedInteger(exponent))
                let attributes = [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
                guard let key = SecKeyCreateWithData(publicKey as CFData, attributes, nil) else { return false }
                return SecKeyVerifySignature(key, .rsaSignatureMessagePKCS1v15SHA256, message as CFData, signature as CFData, nil)
            }
        }
    }

    private enum DER {
        static func unsignedInteger(_ value: Data) -> Data {
            element(0x02, value.first.map { $0 & 0x80 != 0 } == true ? Data([0]) + value : value)
        }

        static func element(_ tag: UInt8, _ value: Data) -> Data {
            guard value.count >= 128 else { return Data([tag, UInt8(value.count)]) + value }
            let high = UInt8(value.count >> 8)
            let low = UInt8(value.count & 0xFF)
            let length = high == 0 ? [UInt8(0x81), low] : [UInt8(0x82), high, low]
            return Data([tag] + length) + value
        }
    }
}
