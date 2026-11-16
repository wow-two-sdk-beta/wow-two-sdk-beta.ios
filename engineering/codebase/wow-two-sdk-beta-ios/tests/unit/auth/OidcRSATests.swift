import Foundation
import Security
import Testing
@testable import WoW2IosAuth
import WoW2IosTestSupport

struct OidcRSATests {
    @Test func verifiesAnRS256TokenUsingTheProvidersPublicModulus() async throws {
        let authority = URL(string: "https://identity.example.test/")!
        let key = try #require(SecKeyCreateRandomKey([
            kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeySizeInBits: 2048,
        ] as CFDictionary, nil))
        let publicKey = try #require(SecKeyCopyPublicKey(key))
        let encoded = try #require(SecKeyCopyExternalRepresentation(publicKey, nil)) as Data
        var outer = TestDER(encoded)
        var values = TestDER(try outer.read(0x30))
        let modulus = Data(try values.read(0x02).drop(while: { $0 == 0 }))
        let exponent = Data(try values.read(0x02).drop(while: { $0 == 0 }))
        let jwks = try JSONSerialization.data(withJSONObject: ["keys": [[
            "kid": "rsa-key", "kty": "RSA", "alg": "RS256", "use": "sig",
            "n": Base64URL.encode(modulus), "e": Base64URL.encode(exponent),
        ]]])
        let provider = OidcProvider(issuer: authority, authorizationEndpoint: authority.appending(path: "authorize"),
            tokenEndpoint: authority.appending(path: "token"), jwksURI: authority.appending(path: "jwks"),
            signingAlgorithms: ["RS256"])
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let reply = StubTransport.Reply.response(status: 200, body: String(decoding: jwks, as: UTF8.self))
        let verifier = OidcIDTokenVerifier(provider: provider, clientID: "native-sdk",
            transport: StubTransport(reply, reply), time: { now })
        let header = #"{"alg":"RS256","kid":"rsa-key","typ":"JWT"}"#
        let claims = #"{"iss":"https://identity.example.test/","aud":"native-sdk","sub":"person","iat":1800000000,"exp":1800000300,"nonce":"expected"}"#
        let body = "\(Base64URL.encode(Data(header.utf8))).\(Base64URL.encode(Data(claims.utf8)))"
        let signature = try #require(SecKeyCreateSignature(
            key, .rsaSignatureMessagePKCS1v15SHA256, Data(body.utf8) as CFData, nil)) as Data
        let token = "\(body).\(Base64URL.encode(signature))"

        let identity = try await verifier.verify(token, context: .signIn(nonce: "expected"))
        #expect(identity.subject == "person")
        await #expect(throws: OidcError.invalidIdentityToken) {
            try await verifier.verify(token, context: .signIn(nonce: "changed"))
        }
    }
}

private struct TestDER {
    private let bytes: [UInt8]
    private var index = 0

    init(_ data: Data) { bytes = Array(data) }

    mutating func read(_ tag: UInt8) throws -> Data {
        #expect(try nextByte() == tag)
        let first = try nextByte()
        let width = Int(first & 0x7F)
        let length: Int
        if first < 0x80 {
            length = Int(first)
        } else {
            #expect((1...2).contains(width))
            var size = 0
            for _ in 0..<width { size = (size << 8) | Int(try nextByte()) }
            length = size
        }
        let end = index + length
        try #require(end <= bytes.count)
        defer { index = end }
        return Data(bytes[index..<end])
    }

    private mutating func nextByte() throws -> UInt8 {
        let value = try #require(bytes.indices.contains(index) ? bytes[index] : nil)
        index += 1
        return value
    }
}
