import UIKit

extension UIImage {
    /// Draws the image upright, as its orientation says it should be seen, and no larger than `maxDimension`.
    /// - Returns: The upright bitmap in sRGB at scale 1, or nil when the image is empty.
    public func uprightImage(maxDimension: CGFloat) -> CGImage? {
        let pixels = CGSize(width: size.width * scale, height: size.height * scale)
        guard pixels.width > 0, pixels.height > 0 else { return nil }
        let shrink = min(1, maxDimension / max(pixels.width, pixels.height))
        let target = CGSize(width: (pixels.width * shrink).rounded(), height: (pixels.height * shrink).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: target, format: format)
            .image { _ in draw(in: CGRect(origin: .zero, size: target)) }
            .cgImage
    }
}
