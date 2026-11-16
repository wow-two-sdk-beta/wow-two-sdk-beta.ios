import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

/// Writes an H.264 MP4 of held, full-frame images at 30 frames per second.
public actor StillVideoWriter {
    public enum WriteError: Error, Equatable, Sendable {
        case invalidDimensions
        case invalidDuration
        case imageDimensions
        case unsupportedEncoding
        case pixelBufferUnavailable
        case emptyVideo
        case operationInProgress
        case closed
        case encodingFailed
    }

    private static let timeScale: CMTimeScale = 30

    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let width: Int
    private let height: Int
    private var frameCount: Int64 = 0
    private var writingFrames = false
    private var closed = false

    /// Creates a writer for an unused file URL and even pixel dimensions.
    public init(outputURL: URL, width: Int, height: Int) throws {
        guard width > 0, height > 0, width.isMultiple(of: 2), height.isMultiple(of: 2) else {
            throw WriteError.invalidDimensions
        }
        self.width = width
        self.height = height

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ]
        guard writer.canApply(outputSettings: settings, forMediaType: .video) else {
            throw WriteError.unsupportedEncoding
        }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        guard writer.canAdd(input) else { throw WriteError.unsupportedEncoding }
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            ]
        )
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? WriteError.encodingFailed }
        writer.startSession(atSourceTime: .zero)

        self.writer = writer
        self.input = input
        self.adaptor = adaptor
    }

    /// Appends one image for the nearest whole number of frames.
    public func append(_ image: CGImage, seconds: Double) async throws {
        guard !closed else { throw WriteError.closed }
        guard !writingFrames else { throw WriteError.operationInProgress }
        guard image.width == width, image.height == height else { throw WriteError.imageDimensions }
        guard let count = Int64(exactly: (seconds * Double(Self.timeScale)).rounded()),
              count > 0, count <= Int64.max - frameCount else {
            throw WriteError.invalidDuration
        }
        writingFrames = true
        defer { writingFrames = false }

        do {
            let buffer = try makePixelBuffer(from: image)
            for _ in 0..<count {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    guard !closed, writer.status == .writing else {
                        throw writer.error ?? WriteError.encodingFailed
                    }
                    try await Task.sleep(for: .milliseconds(4))
                }
                guard !closed, adaptor.append(buffer, withPresentationTime: time(at: frameCount)) else {
                    throw writer.error ?? WriteError.encodingFailed
                }
                frameCount += 1
            }
        } catch {
            cancel()
            throw error
        }
    }

    /// Finalizes the container and returns the file after the encoder has finished.
    public func finish() async throws -> URL {
        guard !closed else { throw WriteError.closed }
        guard !writingFrames else { throw WriteError.operationInProgress }
        guard frameCount > 0 else { throw WriteError.emptyVideo }
        do {
            try Task.checkCancellation()
        } catch {
            cancel()
            throw error
        }

        closed = true
        writer.endSession(atSourceTime: time(at: frameCount))
        input.markAsFinished()
        await writer.finishWriting()
        do {
            guard writer.status == .completed else { throw writer.error ?? WriteError.encodingFailed }
            try Task.checkCancellation()
            return writer.outputURL
        } catch {
            try? FileManager.default.removeItem(at: writer.outputURL)
            throw error
        }
    }

    /// Cancels an unfinished write. A finished video remains available at the output URL.
    public func cancel() {
        guard !closed else { return }
        closed = true
        if writer.status == .writing {
            writer.cancelWriting()
        }
        try? FileManager.default.removeItem(at: writer.outputURL)
    }

    private func time(at frame: Int64) -> CMTime {
        CMTime(value: frame, timescale: Self.timeScale)
    }

    private func makePixelBuffer(from image: CGImage) throws -> CVPixelBuffer {
        guard let pool = adaptor.pixelBufferPool else {
            throw writer.error ?? WriteError.pixelBufferUnavailable
        }
        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
              let pixelBuffer,
              CVPixelBufferLockBaseAddress(pixelBuffer, []) == kCVReturnSuccess else {
            throw WriteError.pixelBufferUnavailable
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
              let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: bitmapInfo) else {
            throw WriteError.pixelBufferUnavailable
        }
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(frame)
        context.draw(image, in: frame)
        return pixelBuffer
    }
}
