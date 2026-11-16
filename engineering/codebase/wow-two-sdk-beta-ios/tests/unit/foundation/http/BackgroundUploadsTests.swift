#if os(iOS)
import Foundation
import Testing
@testable import WoW2IosFoundation

struct BackgroundUploadsTests {
    @Test func aRelaunchedCallerCanPickUpAnUnownedResponseOnce() throws {
        let results = BackgroundUploadResults()
        let body = Data(#"{"data":{"photo":"received"}}"#.utf8)
        let response = httpResponse()
        #expect(results.append(body.prefix(8), task: 15))
        #expect(results.append(body.dropFirst(8), task: 15))
        results.finish(task: 15, id: "same-reviewed-file", response: response, error: nil)

        let received = try #require(results.takeResult(id: "same-reviewed-file")).get()
        #expect(received.0 == body)
        #expect(received.1.statusCode == 200)
        #expect(results.takeResult(id: "same-reviewed-file") == nil)
    }

    @Test func callbackCompletesOnlyTheMatchingTask() async throws {
        let results = BackgroundUploadResults()
        let response = httpResponse()
        let body = Data([1, 2, 3])
        let awaited: BackgroundUploadResults.Value = try await withCheckedThrowingContinuation { continuation in
            #expect(results.attach(continuation, task: 20, id: "current"))
            results.finish(task: 19, id: "old-account", response: nil, error: URLError(.cancelled))
            #expect(results.append(body, task: 20))
            results.finish(task: 20, id: "current", response: response, error: nil)
        }

        #expect(awaited.0 == body)
        #expect(results.takeResult(id: "old-account") == nil)
    }

    @Test func cancellationCompletesTheWaiterAndLeavesStableIDsReusable() async {
        let results = BackgroundUploadResults()
        #expect(results.reserve("first"))
        #expect(!results.reserve("first"))
        #expect(results.reserve("other"))
        await #expect(throws: URLError(.cancelled)) {
            let _: BackgroundUploadResults.Value = try await withCheckedThrowingContinuation { continuation in
                #expect(results.attach(continuation, task: 3, id: "first"))
                results.finish(task: 3, id: "first", response: nil, error: URLError(.cancelled))
            }
        }
        results.release("first")
        #expect(results.reserve("first"))
        #expect(results.takeResult(id: "first") == nil)
    }

    @Test func capsAServerResponseWithoutReplacingTheFailureWithCancellation() async {
        let results = BackgroundUploadResults(responseLimit: 4)
        await #expect(throws: URLError(.dataLengthExceedsMaximum)) {
            let _: BackgroundUploadResults.Value = try await withCheckedThrowingContinuation { continuation in
                #expect(results.attach(continuation, task: 1, id: "oversized"))
                #expect(results.append(Data([1, 2, 3]), task: 1))
                #expect(!results.append(Data([4, 5]), task: 1))
                results.finish(task: 1, id: "oversized", response: httpResponse(), error: URLError(.cancelled))
            }
        }
        #expect(results.takeResult(id: "oversized") == nil)
    }

    private func httpResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://api.example.com/files/1")!,
                        statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}
#endif
