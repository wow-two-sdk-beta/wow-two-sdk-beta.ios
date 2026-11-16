#if os(iOS)
import Foundation
import os

/// A single file-backed URLSession that can reconnect to pending uploads after the app relaunches.
public final class BackgroundUploads: Sendable {
    public let identifier: String
    private let delegate: BackgroundUploadDelegate
    private let state = OSAllocatedUnfairLock<URLSession?>(initialState: nil)

    public init(identifier: String) {
        self.identifier = identifier
        delegate = BackgroundUploadDelegate()
    }

    /// A stable, non-secret ID lets the caller rejoin an upload of the same immutable content after relaunch.
    public func upload(_ request: URLRequest, fromFile file: URL, id: String) async throws -> (Data, HTTPURLResponse) {
        guard let destination = request.url, destination.scheme?.lowercased() == "https",
              destination.host()?.isEmpty == false, destination.user() == nil, destination.password() == nil,
              destination.fragment() == nil, file.isFileURL, !id.isEmpty, id.utf8.count <= 256,
              request.httpBody == nil, request.httpBodyStream == nil
        else { throw URLError(.badURL) }
        try Task.checkCancellation()
        let results = delegate.results
        guard results.reserve(id) else { throw URLError(.resourceUnavailable) }
        defer { results.release(id) }

        let session = session()
        let pending = await session.allTasks.first { $0.taskDescription == id && $0.originalRequest?.url == destination }
        if Task.isCancelled {
            pending?.cancel()
            throw CancellationError()
        }
        if let response = results.takeResult(id: id) { return try Self.direct(response.get(), to: destination) }
        let task = pending ?? session.uploadTask(with: request, fromFile: file)
        if pending == nil { task.taskDescription = id }

        let received: (Data, HTTPURLResponse) = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    task.cancel()
                    continuation.resume(throwing: CancellationError())
                } else if results.attach(continuation, task: task.taskIdentifier, id: id) {
                    if task.state == .suspended { task.resume() }
                } else if pending == nil {
                    task.cancel()
                }
            }
        } onCancel: {
            task.cancel()
        }
        try Task.checkCancellation()
        return try Self.direct(received, to: destination)
    }

    /// Cancels matching persisted tasks as well as uploads that still have a Swift caller.
    public func cancelUploads(includingUnidentified: Bool = false, matching predicate: @Sendable (String) -> Bool) async {
        for task in await session().allTasks where task.taskDescription.map(predicate) ?? includingUnidentified {
            task.cancel()
        }
    }

    /// Forward the UIKit app-delegate event for this identifier. Apple delivers its completion on the main actor.
    public func reconnect(completion: @escaping @MainActor @Sendable () -> Void) {
        delegate.results.addCompletion(completion)
        _ = session()
    }

    private func session() -> URLSession {
        state.withLock { session in
            if let session { return session }
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
            configuration.sessionSendsLaunchEvents = true
            configuration.isDiscretionary = false
            configuration.httpShouldSetCookies = false
            configuration.httpCookieStorage = nil
            configuration.urlCredentialStorage = nil
            let created = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            session = created
            return created
        }
    }

    // Apple follows redirects for background sessions before reporting the final response.
    // Only the direct configured destination may confirm an upload.
    private static func direct(_ result: (Data, HTTPURLResponse), to expected: URL) throws -> (Data, HTTPURLResponse) {
        guard result.1.url == expected else { throw URLError(.httpTooManyRedirects) }
        return result
    }
}

private final class BackgroundUploadDelegate: NSObject, URLSessionDataDelegate {
    let results = BackgroundUploadResults()

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if !results.append(data, task: dataTask.taskIdentifier) { dataTask.cancel() }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        results.finish(task: task.taskIdentifier, id: task.taskDescription, response: task.response, error: error)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let completions = results.takeCompletions()
        Task { @MainActor in
            for completion in completions { completion() }
        }
    }
}

/// Serializes delegate replies and the callers that await them. A relaunched app may see the reply just before it
/// finds the corresponding task in URLSession, so a bounded stash covers that gap.
final class BackgroundUploadResults: Sendable {
    typealias Value = (Data, HTTPURLResponse)
    typealias Reply = Result<Value, any Error>
    typealias Waiter = CheckedContinuation<Value, any Error>
    typealias Completion = @MainActor @Sendable () -> Void

    private struct State: Sendable {
        var buffers: [Int: Data] = [:]
        var oversized: Set<Int> = []
        var waitingIDs: Set<String> = []
        var waiters: [Int: Waiter] = [:]
        var replies: [(id: String, reply: Reply)] = []
        var completions: [Completion] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let responseLimit: Int

    init(responseLimit: Int = 256 * 1024) {
        self.responseLimit = responseLimit
    }

    func reserve(_ id: String) -> Bool { state.withLock { $0.waitingIDs.insert(id).inserted } }

    func release(_ id: String) {
        _ = state.withLock { $0.waitingIDs.remove(id) }
    }

    func takeResult(id: String) -> Reply? {
        state.withLock { value in
            guard let index = value.replies.firstIndex(where: { $0.id == id }) else { return nil }
            return value.replies.remove(at: index).reply
        }
    }

    func attach(_ waiter: Waiter, task: Int, id: String) -> Bool {
        let result: Reply? = state.withLock { value in
            if let index = value.replies.firstIndex(where: { $0.id == id }) {
                return value.replies.remove(at: index).reply
            }
            value.waiters[task] = waiter
            return nil
        }
        if let result { waiter.resume(with: result) }
        return result == nil
    }

    func append(_ chunk: Data, task: Int) -> Bool {
        state.withLock { value in
            let amount = value.buffers[task]?.count ?? 0
            guard !value.oversized.contains(task), chunk.count <= responseLimit - amount else {
                value.buffers[task] = nil
                value.oversized.insert(task)
                return false
            }
            value.buffers[task, default: Data()].append(chunk)
            return true
        }
    }

    func finish(task: Int, id: String?, response: URLResponse?, error: (any Error)?) {
        let delivery: (Waiter?, Reply) = state.withLock { value in
            let data = value.buffers.removeValue(forKey: task) ?? Data()
            let reply: Reply
            if value.oversized.remove(task) != nil {
                reply = .failure(URLError(.dataLengthExceedsMaximum))
            } else if let error {
                reply = .failure(error)
            } else if let http = response as? HTTPURLResponse {
                reply = .success((data, http))
            } else {
                reply = .failure(URLError(.badServerResponse))
            }
            let waiter = value.waiters.removeValue(forKey: task)
            if waiter == nil, let id, (error as? URLError)?.code != .cancelled {
                value.replies.removeAll { $0.id == id }
                value.replies.append((id, reply))
                if value.replies.count > 8 { value.replies.removeFirst() }
            }
            return (waiter, reply)
        }
        delivery.0?.resume(with: delivery.1)
    }

    func addCompletion(_ completion: @escaping Completion) {
        state.withLock { $0.completions.append(completion) }
    }

    func takeCompletions() -> [Completion] {
        state.withLock { value in
            let completions = value.completions
            value.completions.removeAll()
            return completions
        }
    }
}
#endif
