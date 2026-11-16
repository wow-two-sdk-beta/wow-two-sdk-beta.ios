import Foundation

/// Claims from an ID token whose issuer, audience and signature have been verified.
public struct OidcPrincipal: Equatable, Sendable {
    public let subject: String
    public let name: String?
    public let email: String?
    public let phoneNumber: String?

    public var displayName: String? {
        [name, email, phoneNumber].compactMap { $0 }.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
