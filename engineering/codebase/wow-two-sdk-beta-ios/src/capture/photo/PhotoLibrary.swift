import Foundation
import Photos

/// Adds images to the person's photo library, asking only for permission to add.
///
/// The app's Info.plist needs `NSPhotoLibraryAddUsageDescription`.
public enum PhotoLibrary {
    /// Why an image was not saved.
    public enum SaveError: Error, Equatable, Sendable {
        /// The person has not allowed adding to Photos.
        case denied
    }

    /// Asks for add-only access when not yet decided, then adds the encoded image (JPEG, HEIC, PNG) as a new photo.
    /// - Throws: `SaveError.denied` without access; the Photos error when the change fails.
    public static func save(_ data: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }
    }
}
