import Foundation
import Observation
import WoW2IosFoundation

public enum AuthSessionState: Equatable, Sendable {
    case signedOut
    case restoring
    case signingIn
    case signedIn(OidcPrincipal)
}

public enum AuthSessionFailure: Error, Equatable, Sendable {
    case unavailable
    case denied
    case invalidResponse
    case storage
    case signedOutByProvider
}

/// A native public-client session. Signed-in state always comes from an ID token validated for this client.
@MainActor
@Observable
public final class AuthSession {
    public typealias Browser = @MainActor (URL, String) async throws -> URL

    public private(set) var state: AuthSessionState = .signedOut
    /// Suitable for app copy. Provider responses and credentials are never included.
    public private(set) var lastFailure: AuthSessionFailure?

    private struct Account: Sendable {
        let provider: OidcProvider
        let principal: OidcPrincipal
        let tokens: OidcTokens
    }

    @ObservationIgnored private let config: OidcClientConfiguration
    @ObservationIgnored private let store: any TokenStore
    @ObservationIgnored private let transport: any HttpTransport
    @ObservationIgnored private let time: @Sendable () -> Date
    @ObservationIgnored private var account: Account?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var refreshTask: Task<String?, Never>?
    @ObservationIgnored private var storageTail: Task<Void, any Error>?

    public convenience init(configuration: OidcClientConfiguration, store: any TokenStore) {
        self.init(configuration: configuration, store: store, transport: NoRedirectTransport(), time: Date.init)
    }

    init(configuration: OidcClientConfiguration, store: any TokenStore, transport: any HttpTransport,
         time: @escaping @Sendable () -> Date) {
        self.config = configuration
        self.store = store
        self.transport = transport
        self.time = time
    }

    /// The closure `ApiClient` reads before an authenticated request. Configure it only for the app's trusted API.
    public var headers: @Sendable () async -> [String: String] {
        { [weak self] in
            guard let token = await self?.validAccessToken() else { return [:] }
            return ["Authorization": "Bearer \(token)"]
        }
    }

    /// Revalidates a stored ID token before showing the account. A temporary network error preserves credentials.
    public func restore() async throws {
        guard state == .signedOut else { return }
        let epoch = begin(.restoring)
        do {
            if let storageTail {
                do { try await storageTail.value }
                catch { throw AuthSessionFailure.storage }
            }
            try check(epoch)
            let stored: OidcTokens?
            do { stored = try await store.load() }
            catch { throw AuthSessionFailure.storage }
            try check(epoch)
            guard let stored else { state = .signedOut; return }
            guard let idToken = stored.identityToken, OidcTokenEndpoint.canUseAccessToken(stored.accessToken) else {
                throw OidcError.invalidTokenResponse
            }
            let provider = try await OidcProvider.discover(config, transport: transport)
            let principal = try await verifier(for: provider).verify(
                idToken, context: .restore(originalNonce: stored.originalNonce)
            )
            try check(epoch)
            let restored = Account(provider: provider, principal: principal, tokens: stored)
            if stored.expiresAt > time() {
                show(restored)
            } else {
                let renewed = try await refresh(restored)
                try await save(renewed, epoch: epoch)
            }
        } catch {
            try await finishAttempt(error, epoch: epoch, restoring: true)
        }
    }

    /// Starts code flow with a system browser. Cancelling the sheet returns to signed out without a visible failure.
    public func signIn(using browser: Browser) async throws {
        guard state == .signedOut else { return }
        let epoch = begin(.signingIn)
        do {
            let provider = try await OidcProvider.discover(config, transport: transport)
            try check(epoch)
            let attempt = try OidcAuthorizationAttempt(config: config, provider: provider)
            let callback = try await browser(attempt.url, config.redirectScheme)
            try check(epoch)
            let endpoint = try OidcTokenEndpoint(config: config, provider: provider, transport: transport)
            let response = try await endpoint.redeem(callback: callback, attempt: attempt)
            let expiresAt = time().addingTimeInterval(Double(response.expiresIn))
            guard let identity = response.identityToken else { throw OidcError.invalidIdentityToken }
            let principal = try await verifier(for: provider).verify(
                identity, accessToken: response.accessToken, context: .signIn(nonce: attempt.nonce)
            )
            let tokens = OidcTokens(accessToken: response.accessToken, expiresAt: expiresAt,
                                    refreshToken: response.refreshToken, identityToken: identity, originalNonce: attempt.nonce)
            try await save(Account(provider: provider, principal: principal, tokens: tokens), epoch: epoch)
        } catch {
            try await finishAttempt(error, epoch: epoch)
        }
    }

    /// Clears the account immediately and removes stored credentials before returning successfully.
    public func signOut() async throws {
        try await clearAccount(failure: nil)
    }

    /// Returns a still valid access token, sharing one refresh across concurrent requests.
    public func validAccessToken() async -> String? {
        guard !Task.isCancelled, let current = account else { return nil }
        let epoch = generation
        if current.tokens.expiresAt.timeIntervalSince(time()) > 30 { return current.tokens.accessToken }
        guard current.tokens.refreshToken != nil else {
            if current.tokens.expiresAt > time() { return current.tokens.accessToken }
            try? await clearAccount(failure: .signedOutByProvider)
            return nil
        }

        let inFlight: Task<String?, Never>
        if let refreshTask {
            inFlight = refreshTask
        } else {
            inFlight = Task { [weak self] in
                guard let self else { return nil }
                return await self.performRefresh(current, epoch: epoch)
            }
            refreshTask = inFlight
        }
        let token = await inFlight.value
        guard generation == epoch, !Task.isCancelled else { return nil }
        return token
    }

    private func begin(_ next: AuthSessionState) -> UUID {
        generation = UUID()
        lastFailure = nil
        state = next
        return generation
    }

    private func check(_ epoch: UUID) throws {
        guard generation == epoch, !Task.isCancelled else { throw CancellationError() }
    }

    private func verifier(for provider: OidcProvider) -> OidcIDTokenVerifier {
        OidcIDTokenVerifier(provider: provider, clientID: config.clientID, transport: transport, time: time)
    }

    private func refresh(_ current: Account) async throws -> Account {
        guard let refreshToken = current.tokens.refreshToken, !refreshToken.isEmpty else { throw OidcError.invalidGrant }
        let endpoint = try OidcTokenEndpoint(config: config, provider: current.provider, transport: transport)
        let response = try await endpoint.refresh(refreshToken)
        let expiresAt = time().addingTimeInterval(Double(response.expiresIn))
        let principal: OidcPrincipal
        if let identity = response.identityToken {
            principal = try await verifier(for: current.provider).verify(
                identity, accessToken: response.accessToken,
                context: .refresh(subject: current.principal.subject, originalNonce: current.tokens.originalNonce)
            )
        } else {
            principal = current.principal
        }
        let tokens = OidcTokens(
            accessToken: response.accessToken, expiresAt: expiresAt,
            refreshToken: response.refreshToken ?? refreshToken, identityToken: response.identityToken ?? current.tokens.identityToken,
            originalNonce: current.tokens.originalNonce
        )
        return Account(provider: current.provider, principal: principal, tokens: tokens)
    }

    private func performRefresh(_ current: Account, epoch: UUID) async -> String? {
        defer { if generation == epoch { refreshTask = nil } }
        do {
            let renewed = try await refresh(current)
            try await save(renewed, epoch: epoch)
            return renewed.tokens.accessToken
        } catch {
            guard generation == epoch, !Task.isCancelled else { return nil }
            if Self.providerEndedSession(error) {
                try? await clearAccount(failure: .signedOutByProvider)
                return nil
            }
            let failure = Self.failure(for: error)
            lastFailure = failure
            if failure == .unavailable, current.tokens.expiresAt > time() {
                return current.tokens.accessToken
            }
            return nil
        }
    }

    private func save(_ replacement: Account, epoch: UUID) async throws {
        try check(epoch)
        let task = appendStorageOperation { store in try await store.save(replacement.tokens) }
        do { try await task.value }
        catch { throw AuthSessionFailure.storage }
        if generation == epoch, Task.isCancelled {
            // The operation already wrote successfully. Remove it before a later restore can see it.
            try await clearAccount(failure: nil)
            throw CancellationError()
        }
        try check(epoch)
        show(replacement)
    }

    private func show(_ account: Account) {
        self.account = account
        lastFailure = nil
        state = .signedIn(account.principal)
    }

    private func clearAccount(failure: AuthSessionFailure?) async throws {
        generation = UUID()
        let epoch = generation
        account = nil
        refreshTask?.cancel()
        refreshTask = nil
        state = .signedOut
        lastFailure = failure
        let task = appendStorageOperation { store in try await store.remove() }
        do { try await task.value }
        catch {
            if generation == epoch { lastFailure = .storage }
            throw AuthSessionFailure.storage
        }
    }

    private func appendStorageOperation(_ operation: @escaping @Sendable (any TokenStore) async throws -> Void) -> Task<Void, any Error> {
        let previous = storageTail
        let store = store
        let task = Task {
            if let previous { _ = await previous.result }
            try await operation(store)
        }
        storageTail = task
        return task
    }

    private func finishAttempt(_ error: any Error, epoch: UUID, restoring: Bool = false) async throws {
        guard generation == epoch else { return }
        state = .signedOut
        if error is CancellationError || Task.isCancelled { return }
        if restoring && Self.providerEndedSession(error) {
            try await clearAccount(failure: .signedOutByProvider)
            throw AuthSessionFailure.signedOutByProvider
        }
        let failure = Self.failure(for: error)
        lastFailure = failure
        throw failure
    }

    private static func providerEndedSession(_ error: any Error) -> Bool {
        guard let error = error as? OidcError else { return false }
        return error == .invalidGrant || error == .identityChanged
    }

    private static func failure(for error: any Error) -> AuthSessionFailure {
        if let failure = error as? AuthSessionFailure { return failure }
        if error is URLError { return .unavailable }
        if let error = error as? OidcError {
            switch error {
            case .authorizationDenied: return .denied
            case .httpStatus(let status) where status >= 500: return .unavailable
            default: return .invalidResponse
            }
        }
        return .unavailable
    }
}
