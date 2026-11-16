import Foundation
import Photos

/// Adds photos and videos to the person's library, asking only for permission to add.
///
/// The app's Info.plist needs `NSPhotoLibraryAddUsageDescription`.
public enum PhotoLibrary {
    /// Why an asset was not saved.
    public enum SaveError: Error, Equatable, Sendable {
        /// The person has not allowed adding to Photos.
        case denied
    }

    /// Asks for add-only access when not yet decided, then adds the encoded image (JPEG, HEIC, PNG) as a new photo.
    /// - Throws: `SaveError.denied` without access; the Photos error when the change fails.
    public static func save(_ data: Data) async throws {
        try await requireAddAccess()
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }
    }

    /// Adds a video from a local file under the same add-only permission as a photo.
    public static func saveVideo(at url: URL) async throws {
        try await requireAddAccess()
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: url, options: nil)
        }
    }

    private static func requireAddAccess() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
    }
}
