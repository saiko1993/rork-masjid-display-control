import SwiftUI
import PhotosUI
import AVFoundation

@Observable
@MainActor
class BackgroundManager {
    var loadedImage: UIImage?
    var extractedPalette: ExtractedPalette = .default
    var isLoadingImage: Bool = false

    private let fileManager = FileManager.default

    private var backgroundsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Backgrounds", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static let stockAssets: [BackgroundAsset] = [
        BackgroundAsset(
            id: "stock_image_01",
            name: "Night Mosque Sky",
            type: .image,
            sourceURL: "https://images.unsplash.com/photo-1564769625688-92f8e688fe2b?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_image_02",
            name: "Blue Mosque Dawn",
            type: .image,
            sourceURL: "https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_image_03",
            name: "Golden Dome",
            type: .image,
            sourceURL: "https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=1920&q=80",
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_01",
            name: "Starfield Slow",
            type: .motion,
            motionPreset: .starfield,
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_02",
            name: "Crescent Glow",
            type: .motion,
            motionPreset: .crescentGlow,
            isStock: true
        ),
        BackgroundAsset(
            id: "stock_motion_03",
            name: "Floating Lanterns",
            type: .motion,
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
        let stockIds = Set(Self.stockAssets.map(\.id))
        config.gallery.sort { a, b in
            if a.isStock && !b.isStock { return true }
            if !a.isStock && b.isStock { return false }
            if a.isStock && b.isStock {
                let aIdx = Self.stockAssets.firstIndex(where: { $0.id == a.id }) ?? 0
                let bIdx = Self.stockAssets.firstIndex(where: { $0.id == b.id }) ?? 0
                return aIdx < bIdx
            }
            return a.addedAt < b.addedAt
        }
        let _ = stockIds
    }

    func saveImageFromPhotoPicker(item: PhotosPickerItem, name: String) async -> BackgroundAsset? {
        isLoadingImage = true
        defer { isLoadingImage = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        guard let compressed = ImageCompressor.compress(imageData: data, maxDimension: 3840, quality: 0.85) else { return nil }

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        do {
            try compressed.write(to: fileURL)
        } catch {
            return nil
        }

        return BackgroundAsset(
            name: name.isEmpty ? "Custom Photo" : name,
            type: .image,
            localFileName: fileName,
            isStock: false
        )
    }

    func saveImageFromURL(_ urlString: String, name: String) async -> BackgroundAsset? {
        isLoadingImage = true
        defer { isLoadingImage = false }

        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        guard let compressed = ImageCompressor.compress(imageData: data, maxDimension: 3840, quality: 0.85) else { return nil }

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        do {
            try compressed.write(to: fileURL)
        } catch {
            return nil
        }

        return BackgroundAsset(
            name: name.isEmpty ? "Custom Photo" : name,
            type: .image,
            localFileName: fileName,
            isStock: false
        )
    }

    func loadImage(for asset: BackgroundAsset) {
        isLoadingImage = true

        if let localFile = asset.localFileName {
            let fileURL = backgroundsDirectory.appendingPathComponent(localFile)
            if let data = try? Data(contentsOf: fileURL),
               let img = UIImage(data: data) {
                loadedImage = img
                extractedPalette = extractColors(from: img)
                isLoadingImage = false
                return
            }
        }

        if let urlString = asset.sourceURL, let url = URL(string: urlString) {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let img = UIImage(data: data) {
                    loadedImage = img
                    extractedPalette = extractColors(from: img)
                }
                isLoadingImage = false
            }
        } else {
            loadedImage = nil
            isLoadingImage = false
        }
    }

    func deleteAsset(_ asset: BackgroundAsset) {
        guard !asset.isStock else { return }
        if let fileName = asset.localFileName {
            let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: fileURL)
        }
    }

    func localFileURL(for asset: BackgroundAsset) -> URL? {
        guard let fileName = asset.localFileName else { return nil }
        let url = backgroundsDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
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
            primary: Color(red: accentR * 1.2, green: accentG * 1.1, blue: accentB * 0.9),
            accent: Color(red: accentR, green: accentG, blue: accentB),
            glow: Color(red: avgR * 0.3, green: avgG * 0.3, blue: avgB * 0.3)
        )
    }
}
