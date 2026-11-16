import Foundation
import WoW2IosFoundation

/// Provider metadata pinned to the app's configured issuer. Requests do not follow HTTP redirects.
public struct OidcProvider: Sendable {
    public let issuer: URL
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
    public let jwksURI: URL
    let signingAlgorithms: [String]?

    public static func discover(_ config: OidcClientConfiguration) async throws -> Self {
        try await discover(config, transport: NoRedirectTransport())
    }

    static func discover(_ config: OidcClientConfiguration, transport: any HttpTransport) async throws -> Self {
        var request = URLRequest(url: config.discoveryURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else { throw OidcError.httpStatus(response.statusCode) }
        guard let document = try? JSONDecoder().decode(Document.self, from: data) else { throw OidcError.invalidDiscovery }
        guard document.issuer == config.authority.absoluteString else { throw OidcError.unexpectedIssuer }
        guard [document.authorizationEndpoint, document.tokenEndpoint, document.jwksURI].allSatisfy({
            OidcClientConfiguration.isSecureEndpoint($0)
        }) else { throw OidcError.invalidDiscovery }

        return Self(
            issuer: config.authority, authorizationEndpoint: document.authorizationEndpoint,
            tokenEndpoint: document.tokenEndpoint, jwksURI: document.jwksURI,
            signingAlgorithms: document.signingAlgorithms
        )
    }

    private struct Document: Decodable {
        let issuer: String
        let authorizationEndpoint: URL
        let tokenEndpoint: URL
        let jwksURI: URL
        let signingAlgorithms: [String]?

        enum CodingKeys: String, CodingKey {
            case issuer
            case authorizationEndpoint = "authorization_endpoint"
            case tokenEndpoint = "token_endpoint"
            case jwksURI = "jwks_uri"
            case signingAlgorithms = "id_token_signing_alg_values_supported"
        }
    }
}

private final class RejectRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

struct NoRedirectTransport: HttpTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request, delegate: RejectRedirects())
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}
