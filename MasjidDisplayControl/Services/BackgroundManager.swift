import SwiftUI
import PhotosUI
import CryptoKit

@Observable
@MainActor
class BackgroundManager {
    var loadedImage: UIImage?
    var loadedThumbnail: UIImage?
    var extractedPalette: ExtractedPalette = .default
    var isLoadingImage: Bool = false
    var lastError: String?

    private var thumbnailCache: [String: UIImage] = [:]
    private var thumbnailAccessOrder: [String] = []
    private let maxThumbnailCacheSize = 20

    private let fileManager = FileManager.default

    private var rootDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("MasjidBackgrounds", isDirectory: true)
        ensureDirectory(dir)
        return dir
    }

    private var photosDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("photos", isDirectory: true)
        ensureDirectory(dir)
        return dir
    }

    private var gifsDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("gifs", isDirectory: true)
        ensureDirectory(dir)
        return dir
    }

    private var videosDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("videos", isDirectory: true)
        ensureDirectory(dir)
        return dir
    }

    private var thumbsDirectory: URL {
        let dir = rootDirectory.appendingPathComponent("thumbs", isDirectory: true)
        ensureDirectory(dir)
        return dir
    }

    private func ensureDirectory(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func directory(for type: BackgroundType) -> URL {
        switch type {
        case .photo: return photosDirectory
        case .gif: return gifsDirectory
        case .video: return videosDirectory
        default: return photosDirectory
        }
    }

    static let stockAssets: [BackgroundAsset] = [
        BackgroundAsset(
            id: "stock_photo_bundle_01",
            name: "Kaaba Night Sky",
            type: .photo,
            source: .stock,
            localFileName: "bundle://stock_kaaba_night",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_bundle_02",
            name: "Kaaba Historic",
            type: .photo,
            source: .stock,
            localFileName: "bundle://stock_kaaba_historic",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_01",
            name: "Night Mosque Sky",
            type: .photo,
            source: .stock,
            sourceURL: "https://images.unsplash.com/photo-1564769625688-92f8e688fe2b?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_02",
            name: "Blue Mosque Dawn",
            type: .photo,
            source: .stock,
            sourceURL: "https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_03",
            name: "Golden Dome",
            type: .photo,
            source: .stock,
            sourceURL: "https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_04",
            name: "Mosque Silhouette",
            type: .photo,
            source: .stock,
            sourceURL: "https://images.unsplash.com/photo-1519817650390-64a93db51149?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_photo_05",
            name: "Desert Moonrise",
            type: .photo,
            source: .stock,
            sourceURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_gif_01",
            name: "Crescent Stars",
            type: .gif,
            source: .stock,
            sourceURL: "https://media.giphy.com/media/xT9IgzoKnwFNmISR8I/giphy.gif",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_gif_02",
            name: "Night Sky Shimmer",
            type: .gif,
            source: .stock,
            sourceURL: "https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_video_01",
            name: "Night Sky Loop",
            type: .video,
            source: .stock,
            sourceURL: "https://cdn.pixabay.com/video/2020/07/30/45580-445081001_tiny.mp4",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_video_02",
            name: "Mosque Night",
            type: .video,
            source: .stock,
            sourceURL: "https://assets.mixkit.co/videos/4312/4312-720.mp4",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_01",
            name: "Starfield Slow",
            type: .motion,
            source: .stock,
            motionPreset: .starfield,
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_02",
            name: "Crescent Glow",
            type: .motion,
            source: .stock,
            motionPreset: .crescentGlow,
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_03",
            name: "Floating Lanterns",
            type: .motion,
            source: .stock,
            motionPreset: .floatingLanterns,
            isStock: true
        ),
    ]

    func ensureStockAssets(in config: inout BackgroundConfig) {
        for stock in Self.stockAssets {
            if !config.gallery.contains(where: { $0.id == stock.id }) {
                config.gallery.insert(stock, at: 0)
            }
        }
        config.gallery.sort { a, b in
            if a.isStock && !b.isStock { return true }
            if !a.isStock && b.isStock { return false }
            if a.isStock && b.isStock {
                let aIdx = Self.stockAssets.firstIndex(where: { $0.id == a.id }) ?? 0
                let bIdx = Self.stockAssets.firstIndex(where: { $0.id == b.id }) ?? 0
                return aIdx < bIdx
            }
            return a.createdAt < b.createdAt
        }
        config.ensureFallback()
    }

    func saveImageFromPhotoPicker(item: PhotosPickerItem, name: String) async -> BackgroundAsset? {
        isLoadingImage = true
        defer { isLoadingImage = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                lastError = "Could not load image from photo library"
                return nil
            }
            guard data.count < 50_000_000 else {
                lastError = "Image too large (max 50MB)"
                return nil
            }
            return savePhotoData(data, name: name)
        } catch {
            lastError = "Failed to load photo: \(error.localizedDescription)"
            return nil
        }
    }

    func saveImageFromURL(_ urlString: String, name: String) async -> BackgroundAsset? {
        isLoadingImage = true
        defer { isLoadingImage = false }

        guard let url = URL(string: urlString) else {
            lastError = "Invalid URL"
            return nil
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                lastError = "Server returned error"
                return nil
            }
            guard !data.isEmpty else {
                lastError = "Empty response from server"
                return nil
            }
            guard data.count < 50_000_000 else {
                lastError = "Image too large (max 50MB)"
                return nil
            }
            return savePhotoData(data, name: name)
        } catch {
            lastError = "Download failed: \(error.localizedDescription)"
            return nil
        }
    }

    private func savePhotoData(_ data: Data, name: String) -> BackgroundAsset? {
        guard ImageCompressor.isValidImage(data: data) else {
            lastError = "Invalid image data"
            return nil
        }
        guard let compressed = ImageCompressor.compress(imageData: data, maxDimension: 2048, quality: 0.8) else {
            lastError = "Failed to compress image"
            return nil
        }

        let hash = computeHash(compressed)

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        do {
            try compressed.write(to: fileURL)
        } catch {
            return nil
        }

        let thumbName = generateThumbnail(from: compressed, fileName: fileName)

        return BackgroundAsset(
            name: name.isEmpty ? "Custom Photo" : name,
            type: .photo,
            source: .localFile,
            localFileName: "photos/\(fileName)",
            thumbnailFileName: thumbName,
            isStock: false,
            contentHash: hash
        )
    }

    private func generateThumbnail(from data: Data, fileName: String) -> String? {
        guard let thumbData = ImageCompressor.compress(imageData: data, maxDimension: 300, quality: 0.6) else { return nil }

        let thumbName = "thumb_\(fileName)"
        let thumbURL = thumbsDirectory.appendingPathComponent(thumbName)
        do {
            try thumbData.write(to: thumbURL)
            return "thumbs/\(thumbName)"
        } catch {
            return nil
        }
    }

    private func computeHash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    func loadBundleImage(named name: String) -> UIImage? {
        if let path = Bundle.main.path(forResource: name, ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: name, ofType: "jpeg") {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    func isBundleAsset(_ asset: BackgroundAsset) -> Bool {
        asset.localFileName?.hasPrefix("bundle://") == true
    }

    func bundleImageName(for asset: BackgroundAsset) -> String? {
        guard let localFile = asset.localFileName, localFile.hasPrefix("bundle://") else { return nil }
        return String(localFile.dropFirst("bundle://".count))
    }

    func loadImage(for asset: BackgroundAsset) {
        isLoadingImage = true
        loadedImage = nil

        if let bundleName = bundleImageName(for: asset),
           let img = loadBundleImage(named: bundleName) {
            loadedImage = img
            extractedPalette = extractColors(from: img)
            isLoadingImage = false
            return
        }

        let localFile = asset.localFileName
        let sourceURL = asset.sourceURL
        let rootDir = rootDirectory
        let legacyDir = legacyBackgroundsDirectory

        Task.detached(priority: .userInitiated) {
            var result: UIImage?

            if let localFile, !localFile.hasPrefix("bundle://") {
                let fileURL = rootDir.appendingPathComponent(localFile)
                if let data = try? Data(contentsOf: fileURL) {
                    result = Self.downsampleImage(data: data, maxDimension: 1920)
                }

                if result == nil {
                    let legacyURL = legacyDir.appendingPathComponent(localFile)
                    if let data = try? Data(contentsOf: legacyURL) {
                        result = Self.downsampleImage(data: data, maxDimension: 1920)
                    }
                }
            }

            if result == nil, let urlString = sourceURL, let url = URL(string: urlString) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    result = Self.downsampleImage(data: data, maxDimension: 1920)
                }
            }

            await MainActor.run { [result] in
                if let img = result {
                    self.loadedImage = img
                    self.extractedPalette = self.extractColors(from: img)
                } else {
                    self.loadedImage = nil
                }
                self.isLoadingImage = false
            }
        }
    }

    nonisolated private static func downsampleImage(data: Data, maxDimension: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    func loadThumbnail(for asset: BackgroundAsset) -> UIImage? {
        if let cached = thumbnailCache[asset.id] {
            return cached
        }
        return nil
    }

    func loadThumbnailAsync(for asset: BackgroundAsset) {
        guard thumbnailCache[asset.id] == nil else { return }
        Task.detached(priority: .utility) { [self] in
            let img = await loadThumbnailFromDisk(for: asset)
            await MainActor.run {
                guard let img else { return }
                if self.thumbnailCache.count >= self.maxThumbnailCacheSize, let oldest = self.thumbnailAccessOrder.first {
                    self.thumbnailCache.removeValue(forKey: oldest)
                    self.thumbnailAccessOrder.removeFirst()
                }
                self.thumbnailCache[asset.id] = img
                self.thumbnailAccessOrder.append(asset.id)
            }
        }
    }

    private func loadThumbnailFromDisk(for asset: BackgroundAsset) -> UIImage? {
        if let bundleName = bundleImageName(for: asset) {
            return loadBundleImage(named: bundleName)
        }

        if let thumbFile = asset.thumbnailFileName {
            let thumbURL = rootDirectory.appendingPathComponent(thumbFile)
            if let data = try? Data(contentsOf: thumbURL) {
                return Self.downsampleImage(data: data, maxDimension: 300)
            }
        }

        if let localFile = asset.localFileName, !localFile.hasPrefix("bundle://") {
            let fileURL = rootDirectory.appendingPathComponent(localFile)
            if let data = try? Data(contentsOf: fileURL) {
                return Self.downsampleImage(data: data, maxDimension: 300)
            }
        }

        return nil
    }

    func deleteAsset(_ asset: BackgroundAsset) {
        guard !asset.isStock else { return }
        if let fileName = asset.localFileName {
            let fileURL = rootDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: fileURL)
        }
        if let thumbName = asset.thumbnailFileName {
            let thumbURL = rootDirectory.appendingPathComponent(thumbName)
            try? fileManager.removeItem(at: thumbURL)
        }
    }

    func localFileURL(for asset: BackgroundAsset) -> URL? {
        guard let fileName = asset.localFileName else { return nil }
        let url = rootDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: url.path) { return url }
        let legacyURL = legacyBackgroundsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: legacyURL.path) ? legacyURL : nil
    }

    private var legacyBackgroundsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Backgrounds", isDirectory: true)
    }

    func extractColors(from image: UIImage) -> ExtractedPalette {
        guard let cgImage = image.cgImage else { return .default }

        let size = CGSize(width: 20, height: 20)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: Int(size.width * size.height * 4))

        guard let context = CGContext(
            data: &rawData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .default }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        var totalR: Double = 0, totalG: Double = 0, totalB: Double = 0
        var brightR: Double = 0, brightG: Double = 0, brightB: Double = 0
        var brightCount: Double = 0
        let pixelCount = Int(size.width * size.height)

        for i in 0..<pixelCount {
            let offset = i * 4
            let r = Double(rawData[offset]) / 255.0
            let g = Double(rawData[offset + 1]) / 255.0
            let b = Double(rawData[offset + 2]) / 255.0
            totalR += r; totalG += g; totalB += b

            let brightness = (r + g + b) / 3.0
            if brightness > 0.3 && brightness < 0.8 {
                brightR += r; brightG += g; brightB += b
                brightCount += 1
            }
        }

        let avgR = totalR / Double(pixelCount)
        let avgG = totalG / Double(pixelCount)
        let avgB = totalB / Double(pixelCount)

        let accentR = brightCount > 0 ? brightR / brightCount : avgR
        let accentG = brightCount > 0 ? brightG / brightCount : avgG
        let accentB = brightCount > 0 ? brightB / brightCount : avgB

        return ExtractedPalette(
            primary: Color(red: min(accentR * 1.2, 1.0), green: min(accentG * 1.1, 1.0), blue: accentB * 0.9),
            accent: Color(red: accentR, green: accentG, blue: accentB),
            glow: Color(red: avgR * 0.3, green: avgG * 0.3, blue: avgB * 0.3)
        )
    }
}
