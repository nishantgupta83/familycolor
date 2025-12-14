import SwiftUI

extension Color {
    // Kid-friendly color palette
    static let kidColors: [Color] = [
        Color(hex: "FF6B6B"),  // Cherry
        Color(hex: "FFA94D"),  // Tangerine
        Color(hex: "FFE066"),  // Sunshine
        Color(hex: "8BC34A"),  // Lime
        Color(hex: "4CAF50"),  // Grass
        Color(hex: "26A69A"),  // Ocean
        Color(hex: "42A5F5"),  // Sky
        Color(hex: "5C6BC0"),  // Grape
        Color(hex: "AB47BC"),  // Plum
        Color(hex: "F48FB1"),  // Bubblegum
        Color(hex: "8D6E63"),  // Chocolate
        Color(hex: "78909C")   // Cloud
    ]

    static let colorNames: [String] = [
        "Cherry", "Tangerine", "Sunshine", "Lime",
        "Grass", "Ocean", "Sky", "Grape",
        "Plum", "Bubblegum", "Chocolate", "Cloud"
    ]

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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toUIColor() -> UIColor {
        UIColor(self)
    }
}
