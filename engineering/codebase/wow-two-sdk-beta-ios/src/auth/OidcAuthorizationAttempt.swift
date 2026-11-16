import Foundation

/// One browser session. Its state binds the callback; its nonce must bind the verified ID token.
struct OidcAuthorizationAttempt: Sendable {
    let url: URL
    let nonce: String
    let pkce: Pkce
    let configuration: OidcClientConfiguration
    private let state: String

    init(config: OidcClientConfiguration, provider: OidcProvider) throws(OidcError) {
        let state = try Pkce.randomValue()
        let nonce = try Pkce.randomValue()
        let pkce = try Pkce()
        let parameters = [
            ("client_id", config.clientID), ("response_type", "code"),
            ("redirect_uri", config.redirectURI.absoluteString), ("scope", config.scopes.joined(separator: " ")),
            ("state", state), ("nonce", nonce), ("code_challenge", pkce.challenge), ("code_challenge_method", "S256"),
        ]

        guard provider.issuer.absoluteString == config.authority.absoluteString,
              var endpoint = URLComponents(url: provider.authorizationEndpoint, resolvingAgainstBaseURL: false),
              !((endpoint.queryItems ?? []).contains { item in parameters.contains { $0.0 == item.name } })
        else { throw .invalidDiscovery }

        let encoded = OidcForm.encode(parameters)
        endpoint.percentEncodedQuery = [endpoint.percentEncodedQuery, encoded].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "&")
        guard let url = endpoint.url else { throw .invalidDiscovery }

        self.url = url
        self.nonce = nonce
        self.pkce = pkce
        self.state = state
        self.configuration = config
    }

    func code(from callback: URL) throws(OidcError) -> String {
        guard var components = URLComponents(url: callback, resolvingAgainstBaseURL: false),
              components.fragment == nil,
              let items = components.queryItems
        else { throw .invalidCallback }

        components.query = nil
        let states = items.filter { $0.name == "state" }
        let issuers = items.filter { $0.name == "iss" }
        guard components.url?.absoluteString == configuration.redirectURI.absoluteString,
              states.count == 1, states.first?.value == state,
              issuers.isEmpty || (issuers.count == 1 && issuers.first?.value == configuration.authority.absoluteString)
        else { throw .invalidCallback }

        let codes = items.filter { $0.name == "code" }
        let errors = items.filter { $0.name == "error" }
        if errors.count == 1, codes.isEmpty,
           let error = errors.first?.value, !error.isEmpty {
            throw .authorizationDenied
        }
        guard errors.isEmpty, codes.count == 1, let code = codes.first?.value, !code.isEmpty else {
            throw .invalidCallback
        }
        return code
    }

}
