import AVFoundation
import CoreGraphics
import Foundation
import Testing
import WoW2IosCapture

struct StillVideoWriterTests {
    @Test func holdsThreeImagesForHalfASecondEach() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("sequence.mp4")
        let writer = try StillVideoWriter(outputURL: outputURL, width: 1080, height: 1920)
        for value in [0.2, 0.5, 0.8] {
            try await writer.append(try image(width: 1080, height: 1920, gray: value), seconds: 0.5)
        }
        let result = try await writer.finish()
        #expect(result == outputURL)

        let asset = AVURLAsset(url: result)
        let duration = try await asset.load(.duration)
        #expect(duration.seconds == 1.5)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = try #require(tracks.first)
        let size = try await track.load(.naturalSize)
        let rate = try await track.load(.nominalFrameRate)
        let formats = try await track.load(.formatDescriptions)
        let format = try #require(formats.first)
        #expect(size == CGSize(width: 1080, height: 1920))
        #expect(rate == 30)
        #expect(CMFormatDescriptionGetMediaSubType(format) == kCMVideoCodecType_H264)
        #expect(try await asset.loadTracks(withMediaType: .audio).isEmpty)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 10, height: 10)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        var levels: [UInt8] = []
        for frame in [6, 21, 36] {
            let sample = try await generator.image(at: CMTime(value: Int64(frame), timescale: 30))
            let context = try #require(CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 1,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            ))
            context.draw(sample.image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            let value = try #require(context.data).load(as: UInt8.self)
            levels.append(value)
        }
        #expect(levels[0] < levels[1])
        #expect(levels[1] < levels[2])
    }

    @Test func rejectsInvalidImagesAndTimesAndCancelsThePartialFile() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("cancelled.mp4")
        let writer = try StillVideoWriter(outputURL: outputURL, width: 64, height: 64)
        let frame = try image(width: 64, height: 64, gray: 0.3)
        let tooSmall = try image(width: 32, height: 32, gray: 0.4)
        await #expect(throws: StillVideoWriter.WriteError.emptyVideo) { try await writer.finish() }
        await #expect(throws: StillVideoWriter.WriteError.invalidDuration) {
            try await writer.append(frame, seconds: .infinity)
        }
        await #expect(throws: StillVideoWriter.WriteError.imageDimensions) {
            try await writer.append(tooSmall, seconds: 0.5)
        }
        try await writer.append(frame, seconds: 0.5)
        await writer.cancel()
        #expect(!FileManager.default.fileExists(atPath: outputURL.path))
        await #expect(throws: StillVideoWriter.WriteError.closed) { try await writer.finish() }
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func image(width: Int, height: Int, gray: CGFloat) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(gray: gray, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try #require(context.makeImage())
    }
}
