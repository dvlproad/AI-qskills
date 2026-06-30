import SwiftUI

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

public let cardGradients: [(Color, Color)] = [
    (Color(hex: "fb923c"), Color(hex: "ec4899")),
    (Color(hex: "f472b6"), Color(hex: "f43f5e")),
    (Color(hex: "60a5fa"), Color(hex: "6366f1")),
    (Color(hex: "fbbf24"), Color(hex: "f97316")),
    (Color(hex: "34d399"), Color(hex: "14b8a6")),
    (Color(hex: "ef4444"), Color(hex: "a855f7")),
    (Color(hex: "a855f7"), Color(hex: "4f46e5")),
    (Color(hex: "22d3ee"), Color(hex: "3b82f6")),
]
