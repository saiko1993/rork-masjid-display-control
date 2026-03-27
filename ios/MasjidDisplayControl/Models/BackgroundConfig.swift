import SwiftUI

nonisolated enum BackgroundType: String, Codable, CaseIterable, Sendable {
    case solid = "solid"
    case photo = "photo"
    case gif = "gif"
    case video = "video"
    case motion = "motion"

    var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .photo: return "Photo"
        case .gif: return "GIF"
        case .video: return "Video"
        case .motion: return "Motion"
        }
    }

    var icon: String {
        switch self {
        case .solid: return "circle.fill"
        case .photo: return "photo.fill"
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

nonisolated enum AssetSource: String, Codable, Sendable {
    case stock
    case localFile
    case remoteURL
}

nonisolated enum BackgroundIntensity: String, Codable, CaseIterable, Sendable {
    case calm
    case medium
    case rich

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .medium: return "Medium"
        case .rich: return "Rich"
        }
    }

    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .medium: return "circle.hexagongrid.fill"
        case .rich: return "sparkles"
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .calm: return 18
        case .medium: return 14
        case .rich: return 8
        }
    }

    var overlayDarkness: CGFloat {
        switch self {
        case .calm: return 0.50
        case .medium: return 0.35
        case .rich: return 0.20
        }
    }

    var parallaxStrength: CGFloat {
        switch self {
        case .calm: return 0.08
        case .medium: return 0.15
        case .rich: return 0.25
        }
    }

    var particleMultiplier: CGFloat {
        switch self {
        case .calm: return 0.5
        case .medium: return 0.75
        case .rich: return 1.0
        }
    }
}

nonisolated struct BackgroundAsset: Codable, Sendable, Identifiable, Equatable {
    var id: String
    var name: String
    var type: BackgroundType
    var source: AssetSource
    var sourceURL: String?
    var localFileName: String?
    var thumbnailFileName: String?
    var motionPreset: MotionPresetType?
    var isStock: Bool
    var contentHash: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        type: BackgroundType,
        source: AssetSource = .localFile,
        sourceURL: String? = nil,
        localFileName: String? = nil,
        thumbnailFileName: String? = nil,
        motionPreset: MotionPresetType? = nil,
        isStock: Bool = false,
        contentHash: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.source = source
        self.sourceURL = sourceURL
        self.localFileName = localFileName
        self.thumbnailFileName = thumbnailFileName
        self.motionPreset = motionPreset
        self.isStock = isStock
        self.contentHash = contentHash
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        if let newType = try? container.decode(BackgroundType.self, forKey: .type) {
            type = newType
        } else if let raw = try? container.decode(String.self, forKey: .type), raw == "image" {
            type = .photo
        } else {
            type = .solid
        }

        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        localFileName = try container.decodeIfPresent(String.self, forKey: .localFileName)
        thumbnailFileName = try container.decodeIfPresent(String.self, forKey: .thumbnailFileName)
        motionPreset = try container.decodeIfPresent(MotionPresetType.self, forKey: .motionPreset)
        isStock = (try? container.decode(Bool.self, forKey: .isStock)) ?? false
        contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        createdAt = (try? container.decode(Date.self, forKey: .createdAt))
            ?? (try? container.decode(Date.self, forKey: .addedAt))
            ?? Date()

        if let decodedSource = try? container.decode(AssetSource.self, forKey: .source) {
            source = decodedSource
        } else if isStock {
            source = .stock
        } else if sourceURL != nil {
            source = .remoteURL
        } else {
            source = .localFile
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, type, source, sourceURL, localFileName, thumbnailFileName
        case motionPreset, isStock, contentHash, createdAt, addedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(localFileName, forKey: .localFileName)
        try container.encodeIfPresent(thumbnailFileName, forKey: .thumbnailFileName)
        try container.encodeIfPresent(motionPreset, forKey: .motionPreset)
        try container.encode(isStock, forKey: .isStock)
        try container.encodeIfPresent(contentHash, forKey: .contentHash)
        try container.encode(createdAt, forKey: .createdAt)
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
    var intensity: BackgroundIntensity
    var gallery: [BackgroundAsset]

    static let `default` = BackgroundConfig(
        enabled: false,
        activeBackgroundId: nil,
        backgroundType: .solid,
        blurRadius: 14,
        overlayDarkness: 0.35,
        parallaxStrength: 0.2,
        ambientEffect: .none,
        intensity: .medium,
        gallery: []
    )

    init(
        enabled: Bool = false,
        activeBackgroundId: String? = nil,
        backgroundType: BackgroundType = .solid,
        blurRadius: CGFloat = 14,
        overlayDarkness: CGFloat = 0.35,
        parallaxStrength: CGFloat = 0.2,
        ambientEffect: AmbientEffect = .none,
        intensity: BackgroundIntensity = .medium,
        gallery: [BackgroundAsset] = []
    ) {
        self.enabled = enabled
        self.activeBackgroundId = activeBackgroundId
        self.backgroundType = backgroundType
        self.blurRadius = blurRadius
        self.overlayDarkness = overlayDarkness
        self.parallaxStrength = parallaxStrength
        self.ambientEffect = ambientEffect
        self.intensity = intensity
        self.gallery = gallery
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? container.decode(Bool.self, forKey: .enabled)) ?? false
        activeBackgroundId = try container.decodeIfPresent(String.self, forKey: .activeBackgroundId)

        if let newType = try? container.decode(BackgroundType.self, forKey: .backgroundType) {
            backgroundType = newType
        } else if let raw = try? container.decode(String.self, forKey: .backgroundType), raw == "image" {
            backgroundType = .photo
        } else {
            backgroundType = .solid
        }

        blurRadius = (try? container.decode(CGFloat.self, forKey: .blurRadius)) ?? 14
        overlayDarkness = (try? container.decode(CGFloat.self, forKey: .overlayDarkness)) ?? 0.35
        parallaxStrength = (try? container.decode(CGFloat.self, forKey: .parallaxStrength)) ?? 0.2
        ambientEffect = (try? container.decode(AmbientEffect.self, forKey: .ambientEffect)) ?? .none
        intensity = (try? container.decode(BackgroundIntensity.self, forKey: .intensity)) ?? .medium
        gallery = (try? container.decode([BackgroundAsset].self, forKey: .gallery)) ?? []
    }

    var activeBackground: BackgroundAsset? {
        guard let id = activeBackgroundId else { return nil }
        return gallery.first { $0.id == id }
    }

    mutating func applyIntensity(_ level: BackgroundIntensity) {
        intensity = level
        blurRadius = level.blurRadius
        overlayDarkness = level.overlayDarkness
        parallaxStrength = level.parallaxStrength
    }

    mutating func addAsset(_ asset: BackgroundAsset) {
        if gallery.count >= 20 {
            if let idx = gallery.lastIndex(where: { !$0.isStock }) {
                gallery.remove(at: idx)
            }
        }
        if let hash = asset.contentHash,
           gallery.contains(where: { $0.contentHash == hash }) {
            return
        }
        gallery.append(asset)
    }

    mutating func removeAsset(id: String) {
        gallery.removeAll { $0.id == id && !$0.isStock }
        if activeBackgroundId == id {
            activeBackgroundId = gallery.first?.id
        }
    }

    mutating func ensureFallback() {
        if let activeId = activeBackgroundId,
           !gallery.contains(where: { $0.id == activeId }) {
            activeBackgroundId = gallery.first(where: { $0.isStock })?.id ?? gallery.first?.id
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
