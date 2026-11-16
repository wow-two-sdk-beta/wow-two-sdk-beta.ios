#if os(iOS)
import AuthenticationServices
import SwiftUI

@available(iOS 17.4, *)
public extension AuthSession {
    /// Presents the platform's authentication sheet with a private browser session.
    func signIn(using session: WebAuthenticationSession) async throws {
        try await signIn { url, scheme in
            do {
                return try await session.authenticate(
                    using: url, callback: .customScheme(scheme), preferredBrowserSession: .ephemeral,
                    additionalHeaderFields: [:]
                )
            } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
                throw CancellationError()
            }
        }
    }
}
#endif
