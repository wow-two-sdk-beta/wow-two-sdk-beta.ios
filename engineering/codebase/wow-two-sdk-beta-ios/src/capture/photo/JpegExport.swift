import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Encodes a finished image as a JPEG for saving and sharing.
public enum JpegExport {
    /// The default compression quality: visually lossless at a fraction of PNG's size.
    public static let defaultQuality: CGFloat = 0.92

    /// Encodes `image` as a JPEG at `quality` (0 smallest … 1 best); nil when encoding fails.
    public static func jpegData(from image: CGImage, quality: CGFloat = defaultQuality) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}
