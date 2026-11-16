# Native sign-in and AuthSession

Public import is `WoW2IosAuth`. Apps that use only the SDK’s views, Foundation, or camera features link the products they need.

```swift
let oidc = try OidcClientConfiguration(
    authority: configuredAuthority, clientID: configuredClientID,
    redirectURI: URL(string: "com.example.app:/signin")!
)
let tokens = try KeychainTokenStore(service: "com.example.app", configuration: oidc)
let session = AuthSession(configuration: oidc, store: tokens)
let api = ApiClient(config: appConfig, headers: session.headers)
```

Call `try await session.restore()` on startup and retry after connectivity returns if it fails with `.unavailable`.
A SwiftUI view passes `@Environment(\.webAuthenticationSession)` to
`try await session.signIn(using: webAuthenticationSession)` on iOS 17.4 or later. The system sheet requests a
private browser session, and dismissal leaves the user signed out. An app reads `state` and `lastFailure` for
its UI. `try await session.signOut()` completes after the Keychain item is deleted. Pass the headers closure only
to the app’s trusted API.

- The exact HTTPS issuer configured in the app pins discovery. The optional `WoW2IdentityAuthority` and
  `WoW2IdentityClientId` Info.plist keys appear together. The provider’s authenticated metadata names its own
  HTTPS endpoints. Discovery, JWKS, and token HTTP requests decline redirects and use system certificate trust.
- Code flow uses independently generated state, nonce and a 32 byte verifier with S256. The callback must match
  the exact registered reverse-domain URI and state. The SDK omits any client secret.
- The ID token must have a valid RS256 or ES256 signature made by one matching public key from the discovered
  JWKS. Issuer, sole audience, authorized party if present, subject and time claims are checked. Sign-in requires
  the attempt’s nonce. If the ID token carries `at_hash`, verification binds it to the accompanying access token.
  Refresh rejects a changed subject or a changed nonce. Claims reach `OidcPrincipal` only after verification.
- A restore revalidates the stored ID token signature before showing a profile. Its historical token may be expired,
  since the separate access token expiry controls access. An expired access token has to refresh before restore
  completes. On a temporary startup outage credentials stay in the Keychain for the next restore attempt.
- Concurrent requests share a single refresh. A provider's `invalid_grant` clears local credentials. In-flight
  network results are invalidated when signing out, and storage operations are ordered so a queued save finishes
  before deletion. Keychain items stay on this device and are separate for each issuer and client.
- Release checks cover signed test identities and a mocked browser/transport. A provider deployment and a registered
  native callback are required to verify a real sign-in on the iPhone.

Sources: [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html),
[OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html),
[PKCE](https://www.rfc-editor.org/rfc/rfc7636.html), [OAuth for Native Apps](https://www.rfc-editor.org/rfc/rfc8252.html).
