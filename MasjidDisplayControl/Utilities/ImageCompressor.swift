import UIKit

enum ImageCompressor {
    static func compress(imageData: Data, maxDimension: CGFloat = 1920, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let size = image.size
        let scale: CGFloat
        if size.width > size.height {
            scale = size.width > maxDimension ? maxDimension / size.width : 1.0
        } else {
            scale = size.height > maxDimension ? maxDimension / size.height : 1.0
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: quality)
    }
}
