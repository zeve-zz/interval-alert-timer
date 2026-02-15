import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let backgroundDeep = Color(hex: 0x0F1114)
    static let backgroundSurface = Color(hex: 0x1A1D21)
    static let backgroundRaised = Color(hex: 0x242830)
    static let backgroundDivider = Color(hex: 0x2E3239)

    // MARK: - Accent Colors
    static let accent = Color(hex: 0xA8B5A0)        // Sage
    static let accentMuted = Color(hex: 0x5C6358)    // Olive dusk

    // MARK: - Text
    static let textPrimary = Color(hex: 0xE8E4DF)
    static let textSecondary = Color(hex: 0x9A958E)
    static let textTertiary = Color(hex: 0x5A5650)

    // MARK: - Ring
    static let ringTrack = Color(hex: 0x1E2226)

    // MARK: - Semantic
    static let destructive = Color(hex: 0xB87272)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
