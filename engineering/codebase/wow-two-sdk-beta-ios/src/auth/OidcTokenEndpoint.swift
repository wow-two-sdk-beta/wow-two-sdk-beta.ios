import Foundation
import WoW2IosFoundation

/// Transport for a native client. It does not interpret ID token claims or make an account signed in.
struct OidcTokenEndpoint: Sendable {
    private let configuration: OidcClientConfiguration
    private let provider: OidcProvider
    private let transport: any HttpTransport

    init(config: OidcClientConfiguration, provider: OidcProvider, transport: any HttpTransport = NoRedirectTransport()) throws(OidcError) {
        guard config.authority.absoluteString == provider.issuer.absoluteString else { throw .unexpectedIssuer }
        self.configuration = config
        self.provider = provider
        self.transport = transport
    }

    func redeem(callback: URL, attempt: OidcAuthorizationAttempt) async throws -> UnverifiedOidcTokenResponse {
        guard attempt.configuration == configuration else { throw OidcError.invalidCallback }
        let code = try attempt.code(from: callback)

        return try await request([
            ("grant_type", "authorization_code"),
            ("code", code),
            ("redirect_uri", configuration.redirectURI.absoluteString),
            ("code_verifier", attempt.pkce.verifier),
        ])
    }

    func refresh(_ refreshToken: String) async throws -> UnverifiedOidcTokenResponse {
        guard !refreshToken.isEmpty else { throw OidcError.invalidGrant }
        return try await request([
            ("grant_type", "refresh_token"),
            ("refresh_token", refreshToken),
        ])
    }

    private func request(_ grant: [(String, String)]) async throws -> UnverifiedOidcTokenResponse {
        var request = URLRequest(url: provider.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(OidcForm.encode([("client_id", configuration.clientID)] + grant).utf8)

        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 400,
               let problem = try? JSONDecoder().decode(Rejection.self, from: data),
               problem.error == "invalid_grant" {
                throw OidcError.invalidGrant
            }
            throw OidcError.httpStatus(response.statusCode)
        }

        guard let tokens = try? JSONDecoder().decode(UnverifiedOidcTokenResponse.self, from: data),
              tokens.expiresIn > 0, tokens.tokenType.caseInsensitiveCompare("Bearer") == .orderedSame,
              Self.canUseAccessToken(tokens.accessToken)
        else { throw OidcError.invalidTokenResponse }
        return tokens
    }

    static func canUseAccessToken(_ token: String) -> Bool {
        !token.isEmpty && token.utf8.allSatisfy(isBearerCharacter)
    }

    private static func isBearerCharacter(_ byte: UInt8) -> Bool {
        (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
            || "-._~+/=".utf8.contains(byte)
    }

    private struct Rejection: Decodable {
        let error: String
    }
}

/// Syntactically valid bearer response; the eventual AuthSession must validate identity separately.
struct UnverifiedOidcTokenResponse: Decodable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let identityToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case identityToken = "id_token"
    }

    var description: String { "UnverifiedOidcTokenResponse(redacted)" }
    var debugDescription: String { description }
}

enum OidcForm {
    static func encode(_ values: [(String, String)]) -> String {
        values.map { key, value in "\(escape(key))=\(escape(value))" }.joined(separator: "&")
    }

    private static func escape(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed)!
    }
}
