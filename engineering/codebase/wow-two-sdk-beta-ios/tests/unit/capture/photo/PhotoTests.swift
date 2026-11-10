import CoreGraphics
import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
import WoW2IosCapture

/// A solid sRGB bitmap of the given size.
private func solid(width: Int, height: Int) throws -> CGImage {
    let context = try #require(CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ))
    context.setFillColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return try #require(context.makeImage())
}

/// `image` encoded as a JPEG tagged with an EXIF `orientation`.
private func jpeg(_ image: CGImage, orientation: Int = 1) throws -> Data {
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
}

@Suite("PhotoImport")
struct PhotoImportTests {
    @Test func pickerFileReadingStopsAtItsByteBudget() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let bytes = Data(repeating: 42, count: 16)
        try bytes.write(to: url)
        #expect(throws: PhotoImport.Failure.tooLarge) { try PhotoImport.read(url, maximumBytes: 8) }
        #expect(try PhotoImport.read(url, maximumBytes: 16) == bytes)
    }

    @Test func aMissingFileIsUnreadable() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(throws: PhotoImport.Failure.unreadable) { try PhotoImport.read(url) }
    }

    @Test func invalidAndOversizedInputsAreRejectedBeforeDecoding() {
        #expect(throws: PhotoImport.Failure.unreadable) { try PhotoImport.decode(Data()) }
        #expect(throws: PhotoImport.Failure.unreadable) { try PhotoImport.decode(Data([1, 2])) }
        #expect(throws: PhotoImport.Failure.tooLarge) { try PhotoImport.decode(Data(count: PhotoImport.maximumBytes + 1)) }
    }

    @Test func encodedOrientationIsAppliedAndLargePhotosAreDownsampled() throws {
        let data = try jpeg(try solid(width: 3200, height: 400), orientation: 6)
        let result = try PhotoImport.decode(data)
        #expect(result.width == 375 && result.height == 3000)
    }

    @Test func theWorkingDimensionIsAParameter() throws {
        let data = try jpeg(try solid(width: 800, height: 400))
        let result = try PhotoImport.decode(data, workingDimension: 200)
        #expect(result.width == 200 && result.height == 100)
    }

    @Test func thePixelBudgetRejectsFromTheHeader() throws {
        let data = try jpeg(try solid(width: 100, height: 100))
        #expect(throws: PhotoImport.Failure.tooLarge) { try PhotoImport.decode(data, maximumPixels: 9_999) }
        #expect(try PhotoImport.decode(data, maximumPixels: 10_000).width == 100)
    }
}

@Suite("JpegExport")
struct JpegExportTests {
    @Test func theExportIsAJpegThatDecodesAtFullSize() throws {
        let data = try #require(JpegExport.jpegData(from: try solid(width: 120, height: 80)))
        #expect(data.prefix(3) == Data([0xFF, 0xD8, 0xFF]))
        let decoded = try PhotoImport.decode(data)
        #expect(decoded.width == 120 && decoded.height == 80)
    }

    @Test func lowerQualityEncodesSmaller() throws {
        let image = try PhotoImport.decode(try jpeg(try solid(width: 400, height: 400)))
        let best = try #require(JpegExport.jpegData(from: image, quality: 1))
        let small = try #require(JpegExport.jpegData(from: image, quality: 0.1))
        #expect(small.count < best.count)
    }
}

@Suite("UIImage.uprightImage")
struct UprightImageTests {
    @Test func anUprightImageTurnsARotatedPhotoAndCapsItsSize() throws {
        // A 400 × 200 bitmap tagged as shot with the camera turned: it should be seen 200 wide and 400 tall.
        let turned = UIImage(cgImage: try solid(width: 400, height: 200), scale: 1, orientation: .right)

        let upright = try #require(turned.uprightImage(maxDimension: 3000))
        let capped = try #require(turned.uprightImage(maxDimension: 100))

        #expect(upright.width == 200 && upright.height == 400)
        #expect(capped.width == 50 && capped.height == 100)
    }

    @Test func anEmptyImageHasNoUprightBitmap() {
        #expect(UIImage().uprightImage(maxDimension: 100) == nil)
    }
}
