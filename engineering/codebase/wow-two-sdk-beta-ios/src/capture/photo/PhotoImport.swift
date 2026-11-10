import CoreGraphics
import CoreTransferable
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Decodes a bounded, upright working image instead of inflating an imported full-resolution photo.
public enum PhotoImport {
    /// The default byte budget of one imported file: 40 MB.
    public static let maximumBytes = 40 * 1024 * 1024
    /// The default pixel budget of one imported image: 80 megapixels.
    public static let maximumPixels = 80_000_000
    /// The default longest side of the decoded working image, in pixels.
    public static let workingDimension = 3000

    /// Why a photo was not imported.
    public enum Failure: Error, Equatable, Sendable {
        /// Not an image ImageIO can read, or an empty file.
        case unreadable
        /// Over the byte or pixel budget.
        case tooLarge

        /// An English message for the person, describing the default budgets; an app may use it as a catalogue key.
        public var message: String {
            switch self {
            case .unreadable: "This photo could not be read. Choose a JPEG, HEIC or PNG photo."
            case .tooLarge: "This photo is too large. Choose a photo under 40 MB and 80 megapixels."
            }
        }
    }

    /// Streams no more than `maximumBytes` plus one byte from `url` (the system picker's temporary file).
    /// - Throws: `Failure.tooLarge` past the budget, `Failure.unreadable` when the file cannot be opened.
    public static func read(_ url: URL, maximumBytes: Int = maximumBytes) throws -> Data {
        guard maximumBytes >= 0, let stream = InputStream(url: url) else { throw Failure.unreadable }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let count = stream.read(&buffer, maxLength: min(buffer.count, maximumBytes - data.count + 1))
            guard count >= 0 else { throw Failure.unreadable }
            if count == 0 { return data }
            guard count <= maximumBytes - data.count else { throw Failure.tooLarge }
            data.append(contentsOf: buffer.prefix(count))
        }
    }

    /// Decodes `data` upright (its EXIF orientation applied) with its longest side at most `workingDimension`.
    ///
    /// The budgets are checked from the header, before any pixel is decoded.
    /// - Throws: `Failure.tooLarge` past a budget, `Failure.unreadable` for anything ImageIO cannot read.
    public static func decode(
        _ data: Data,
        workingDimension: Int = workingDimension,
        maximumBytes: Int = maximumBytes,
        maximumPixels: Int = maximumPixels
    ) throws -> CGImage {
        guard data.count <= maximumBytes else { throw Failure.tooLarge }
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw Failure.unreadable }
        guard width <= maximumPixels / height else { throw Failure.tooLarge }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: workingDimension,
                                        kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw Failure.unreadable
        }
        return image
    }
}

/// A picked photo's bytes, read inside the picker transfer's temporary-file lifetime, before the provider removes it.
///
/// Load it with `PhotosPickerItem.loadTransferable(type: ImportedPhoto.self)`; the read stops at
/// `PhotoImport.maximumBytes`.
public struct ImportedPhoto: Transferable, Sendable {
    /// The file's bytes, at most `PhotoImport.maximumBytes`.
    public let data: Data

    /// Wraps already-read bytes.
    public init(data: Data) {
        self.data = data
    }

    /// Imports any image file through `PhotoImport.read(_:maximumBytes:)`.
    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            ImportedPhoto(data: try PhotoImport.read(received.file))
        }
    }
}
