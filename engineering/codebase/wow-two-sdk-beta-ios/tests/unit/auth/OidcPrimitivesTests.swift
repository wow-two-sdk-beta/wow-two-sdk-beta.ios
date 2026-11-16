import Foundation
import Testing
@testable import WoW2IosAuth
import WoW2IosFoundation
import WoW2IosTestSupport

@Suite("OIDC primitives")
struct OidcPrimitivesTests {
    private let authority = URL(string: "https://identity.example.test/tenant")!
    private let callback = URL(string: "com.example.app:/signin")!

    @Test func usesThePublishedS256VerificationVector() {
        let known = Pkce(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(known.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(String(reflecting: known) == "Pkce(redacted)")
    }

    @Test func discoveryUsesThePinnedIssuerPathAndRequiresTls() async throws {
        let config = try configuration()
        let transport = transport()
        let provider = try await OidcProvider.discover(config, transport: transport)

        #expect(provider.issuer == authority)
        #expect(transport.requests.first?.url?.absoluteString == "https://identity.example.test/tenant/.well-known/openid-configuration")

        await #expect(throws: OidcError.unexpectedIssuer) {
            try await OidcProvider.discover(config, transport: self.transport(issuer: "https://identity.example.test/tenant/"))
        }
        await #expect(throws: OidcError.invalidDiscovery) {
            try await OidcProvider.discover(config, transport: self.transport(tokenScheme: "http"))
        }
    }

    @Test func correlatesAnExactCallbackWithOneSignInAttempt() async throws {
        let config = try configuration()
        let provider = try await OidcProvider.discover(config, transport: transport())
        let attempt = try OidcAuthorizationAttempt(config: config, provider: provider)
        let other = try OidcAuthorizationAttempt(config: config, provider: provider)
        let authorization = try #require(URLComponents(url: attempt.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (authorization.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        let state = try #require(query["state"])
        #expect(state.count == 43)
        #expect(attempt.nonce.count == 43)
        #expect(attempt.nonce != other.nonce)
        #expect(attempt.pkce.verifier != other.pkce.verifier)
        #expect(query["code_challenge_method"] == "S256")
        #expect(query["code_challenge"] == attempt.pkce.challenge)
        #expect(query["redirect_uri"] == callback.absoluteString)
        #expect(query["client_id"] == "native+ios")
        #expect(authorization.percentEncodedQuery?.contains("native%2Bios") == true)

        let valid = URL(string: "\(callback.absoluteString)?code=verified&state=\(state)")!
        #expect(try attempt.code(from: valid) == "verified")
        #expect(throws: OidcError.invalidCallback) { try other.code(from: valid) }
        for URI in [
            "com.example.app:/wrong?code=verified&state=\(state)",
            "com.example.app:/signin?code=verified&state=\(state)&state=other",
            "com.example.app:/signin?code=verified&code=other&state=\(state)",
            "com.example.app:/signin?code=verified&state=\(state)&iss=https://other.example.test",
        ] {
            #expect(throws: OidcError.invalidCallback) { try attempt.code(from: URL(string: URI)!) }
        }
        let denial = URL(string: "\(callback.absoluteString)?error=access_denied&state=\(state)")!
        #expect(throws: OidcError.authorizationDenied) { try attempt.code(from: denial) }
    }

    @Test func buildConfigurationRequiresAnOptionalIdentityPairAndHttps() throws {
        let base = ["WoW2Environment": "dev", "WoW2ApiBaseURL": "http://localhost"]
        let localOnly = try AppConfig.load(from: base)
        #expect(localOnly.identityAuthority == nil)

        let integrated = try AppConfig.load(from: base.merging([
            "WoW2IdentityAuthority": authority.absoluteString, "WoW2IdentityClientId": "native-ios",
        ]) { _, new in new })
        #expect(integrated.identityAuthority == authority)
        #expect(integrated.identityClientID == "native-ios")

        #expect(throws: AppConfigError.missing(key: "WoW2IdentityClientId")) {
            try AppConfig.load(from: base.merging(["WoW2IdentityAuthority": authority.absoluteString]) { _, new in new })
        }
        #expect(throws: AppConfigError.invalidIdentityAuthority(key: "WoW2IdentityAuthority")) {
            try AppConfig.load(from: base.merging([
                "WoW2IdentityAuthority": "http://identity.example.test", "WoW2IdentityClientId": "native-ios",
            ]) { _, new in new })
        }
    }

    @Test func tokensCanBeReplacedAndRemovedWithoutLeakingTheirDescription() async {
        let store = MemoryTokenStore()
        let time = Date(timeIntervalSince1970: 1000)
        let initial = OidcTokens(accessToken: "access-one", expiresAt: time, refreshToken: "refresh-one")
        let refreshed = OidcTokens(accessToken: "access-two", expiresAt: time.addingTimeInterval(60), refreshToken: "refresh-two")

        await store.save(initial)
        #expect(await store.load() == initial)
        await store.save(refreshed)
        #expect(await store.load() == refreshed)
        #expect(String(reflecting: refreshed) == "OidcTokens(redacted)")
        await store.remove()
        #expect(await store.load() == nil)
    }

    @Test func nativeExchangeAndRefreshDoNotSendAClientSecret() async throws {
        let config = try configuration()
        let provider = try await OidcProvider.discover(config, transport: transport())
        let attempt = try OidcAuthorizationAttempt(config: config, provider: provider)
        let state = try #require(URLComponents(url: attempt.url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "state" }?.value)
        let transport = StubTransport.json(200, #"{"access_token":"signed.jwt","token_type":"Bearer","expires_in":600,"refresh_token":"new-refresh"}"#)
        let endpoint = try OidcTokenEndpoint(config: config, provider: provider, transport: transport)

        let token = try await endpoint.redeem(callback: URL(string: "\(callback.absoluteString)?code=fake%2Bcode&state=\(state)")!, attempt: attempt)
        #expect(token.accessToken == "signed.jwt")
        #expect(String(reflecting: token) == "UnverifiedOidcTokenResponse(redacted)")
        let exchange = try #require(transport.requests.first)
        #expect(exchange.url == provider.tokenEndpoint)
        #expect(exchange.httpMethod == "POST")
        #expect(exchange.value(forHTTPHeaderField: "Authorization") == nil)
        let exchangeBody = String(decoding: try #require(exchange.httpBody), as: UTF8.self)
        #expect(exchangeBody.contains("client_id=native%2Bios"))
        #expect(exchangeBody.contains("code=fake%2Bcode"))
        #expect(exchangeBody.contains("code_verifier=\(attempt.pkce.verifier)"))
        #expect(!exchangeBody.contains("client_secret"))

        let wrongConfig = try OidcClientConfiguration(authority: authority, clientID: "other", redirectURI: callback)
        let mismatched = try OidcTokenEndpoint(config: wrongConfig, provider: provider, transport: transport)
        await #expect(throws: OidcError.invalidCallback) {
            try await mismatched.redeem(callback: URL(string: "\(callback.absoluteString)?code=fake&state=\(state)")!, attempt: attempt)
        }
        #expect(transport.requests.count == 1)

        let revoked = StubTransport.json(400, #"{"error":"invalid_grant","error_description":"not surfaced"}"#)
        let refreshEndpoint = try OidcTokenEndpoint(config: config, provider: provider, transport: revoked)
        await #expect(throws: OidcError.invalidGrant) { try await refreshEndpoint.refresh("stale+value") }
        let refresh = try #require(revoked.requests.first)
        let refreshBody = String(decoding: try #require(refresh.httpBody), as: UTF8.self)
        #expect(refreshBody == "client_id=native%2Bios&grant_type=refresh_token&refresh_token=stale%2Bvalue")
    }

    private func configuration() throws -> OidcClientConfiguration {
        try OidcClientConfiguration(authority: authority, clientID: "native+ios", redirectURI: callback)
    }

    private func transport(issuer: String? = nil, tokenScheme: String = "https") -> StubTransport {
        .json(200, """
        {"issuer":"\(issuer ?? authority.absoluteString)",
         "authorization_endpoint":"https://identity.example.test/connect/authorize",
         "token_endpoint":"\(tokenScheme)://identity.example.test/connect/token",
         "jwks_uri":"https://identity.example.test/.well-known/jwks"}
        """)
    }
}
