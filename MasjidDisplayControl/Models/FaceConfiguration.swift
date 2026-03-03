import SwiftUI

nonisolated struct FaceConfiguration: Codable, Sendable, Equatable {
    var faceId: FaceId
    var themeId: ThemeId
    var enabledComponents: Set<FaceComponentId>

    static let `default` = FaceConfiguration(
        faceId: .classicSplit,
        themeId: .islamicGeoDark,
        enabledComponents: [.clock, .dateBlock, .prayerTable, .countdownText, .ticker, .footer, .phaseBadge]
    )

    func hasComponent(_ component: FaceComponentId) -> Bool {
        enabledComponents.contains(component)
    }
}

nonisolated struct FacePayload: Codable, Sendable {
    let faceId: String
    let enabledComponents: [String]
}
