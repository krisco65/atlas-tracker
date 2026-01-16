import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color(hex: "#0A0A0A")
    static let backgroundSecondary = Color(hex: "#1C1C1E")
    static let backgroundTertiary = Color(hex: "#2C2C2E")

    // MARK: - Accent Colors
    static let accentPrimary = Color(hex: "#007AFF")
    static let accentSecondary = Color(hex: "#30D158")

    // MARK: - Category Colors
    static let categorySuplement = Color(hex: "#30D158")
    static let categoryPED = Color(hex: "#007AFF")
    static let categoryPeptide = Color(hex: "#BF5AF2")
    static let categoryMedicine = Color(hex: "#FF9F0A")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#636366")

    // MARK: - Status Colors
    static let statusWarning = Color(hex: "#FFD60A")
    static let statusError = Color(hex: "#FF453A")
    static let statusSuccess = Color(hex: "#30D158")

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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
