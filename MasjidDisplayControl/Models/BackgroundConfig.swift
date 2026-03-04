import SwiftUI

nonisolated enum BackgroundType: String, Codable, CaseIterable, Sendable {
    case solid = "solid"
    case image = "image"
    case gif = "gif"
    case video = "video"
    case motion = "motion"

    var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .image: return "Photo"
        case .gif: return "GIF"
        case .video: return "Video"
        case .motion: return "Motion"
        }
    }

    var icon: String {
        switch self {
        case .solid: return "circle.fill"
        case .image: return "photo.fill"
        case .gif: return "livephoto"
        case .video: return "play.rectangle.fill"
        case .motion: return "sparkles"
        }
    }
}

nonisolated enum MotionPresetType: String, Codable, CaseIterable, Sendable {
    case starfield = "starfield"
    case crescentGlow = "crescentGlow"
    case floatingLanterns = "floatingLanterns"
    case gentleClouds = "gentleClouds"
    case mosqueSilhouetteFog = "mosqueSilhouetteFog"

    var displayName: String {
        switch self {
        case .starfield: return "Starfield Slow"
        case .crescentGlow: return "Crescent Glow"
        case .floatingLanterns: return "Floating Lanterns"
        case .gentleClouds: return "Gentle Clouds"
        case .mosqueSilhouetteFog: return "Mosque Fog"
        }
    }

    var icon: String {
        switch self {
        case .starfield: return "star.fill"
        case .crescentGlow: return "moon.fill"
        case .floatingLanterns: return "lamp.desk.fill"
        case .gentleClouds: return "cloud.fill"
        case .mosqueSilhouetteFog: return "building.2.fill"
        }
    }
}

nonisolated enum AmbientEffect: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case stars = "stars"
    case crescentGlow = "crescentGlow"
    case lanternParticles = "lanternParticles"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .stars: return "Stars"
        case .crescentGlow: return "Crescent Glow"
        case .lanternParticles: return "Lantern Particles"
        }
    }
}

nonisolated struct BackgroundAsset: Codable, Sendable, Identifiable, Equatable {
    var id: String
    var name: String
    var type: BackgroundType
    var sourceURL: String?
    var localFileName: String?
    var motionPreset: MotionPresetType?
    var isStock: Bool
    var addedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        type: BackgroundType,
        sourceURL: String? = nil,
        localFileName: String? = nil,
        motionPreset: MotionPresetType? = nil,
        isStock: Bool = false,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.sourceURL = sourceURL
        self.localFileName = localFileName
        self.motionPreset = motionPreset
        self.isStock = isStock
        self.addedAt = addedAt
    }
}

nonisolated struct BackgroundConfig: Codable, Sendable, Equatable {
    var enabled: Bool
    var activeBackgroundId: String?
    var backgroundType: BackgroundType
    var blurRadius: CGFloat
    var overlayDarkness: CGFloat
    var parallaxStrength: CGFloat
    var ambientEffect: AmbientEffect
    var gallery: [BackgroundAsset]

    static let `default` = BackgroundConfig(
        enabled: false,
        activeBackgroundId: nil,
        backgroundType: .solid,
        blurRadius: 14,
        overlayDarkness: 0.35,
        parallaxStrength: 0.2,
        ambientEffect: .none,
        gallery: []
    )

    var activeBackground: BackgroundAsset? {
        guard let id = activeBackgroundId else { return nil }
        return gallery.first { $0.id == id }
    }

    var effectiveBlurRadius: CGFloat {
        blurRadius
    }

    mutating func addAsset(_ asset: BackgroundAsset) {
        if gallery.count >= 10 {
            if let idx = gallery.lastIndex(where: { !$0.isStock }) {
                gallery.remove(at: idx)
            }
        }
        gallery.append(asset)
    }

    mutating func removeAsset(id: String) {
        gallery.removeAll { $0.id == id && !$0.isStock }
        if activeBackgroundId == id {
            activeBackgroundId = gallery.first?.id
        }
    }
}

nonisolated struct ExtractedPalette: Sendable, Equatable {
    let primary: Color
    let accent: Color
    let glow: Color

    static let `default` = ExtractedPalette(
        primary: Color(red: 0.85, green: 0.68, blue: 0.32),
        accent: Color(red: 0.18, green: 0.25, blue: 0.50),
        glow: Color(red: 0.05, green: 0.05, blue: 0.15)
    )
}
