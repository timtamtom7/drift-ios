import SwiftUI

// MARK: - Theme Colors
enum Theme {
    static let purple = Color(hex: "7C3AED")
    static let deepPurple = Color(hex: "1E1B4B")
    static let surface = Color(hex: "1A1A2E")
    static let surfaceLight = Color(hex: "25253A")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0B0")

    // MARK: - Score Colors
    static let insightAccent = Color(hex: "34d399")
    static let warningAccent = Color(hex: "fbbf24")
    static let heartRate = Color(hex: "ef4444")

    static func scoreColor(for score: Int) -> Color {
        if score >= 80 { return insightAccent }
        if score >= 60 { return warningAccent }
        return heartRate
    }

    // MARK: - Sleep Stage Colors
    static let deepSleep = Color(hex: "4f46e5")
    static let remSleep = Color(hex: "7c3aed")
    static let lightSleep = Color(hex: "6366f1")
    static let awake = Color(hex: "f59e0b")
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
