import SwiftUI

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - Published Properties
    @Published var colorPalette: ColorPaletteType {
        didSet { UserDefaults.standard.set(colorPalette.rawValue, forKey: "colorPalette") }
    }

    @Published var ageMode: AgeMode {
        didSet { UserDefaults.standard.set(ageMode.rawValue, forKey: "ageMode") }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled") }
    }

    @Published var showHints: Bool {
        didSet { UserDefaults.standard.set(showHints, forKey: "showHints") }
    }

    // MARK: - Enums
    enum ColorPaletteType: String, CaseIterable, Identifiable {
        case vibrant = "Vibrant"
        case pastel = "Pastel"
        case earth = "Earth Tones"
        case rainbow = "Rainbow"

        var id: String { rawValue }

        var colors: [Color] {
            switch self {
            case .vibrant:
                return Color.vibrantColors
            case .pastel:
                return Color.pastelColors
            case .earth:
                return Color.earthColors
            case .rainbow:
                return Color.rainbowColors
            }
        }

        var icon: String {
            switch self {
            case .vibrant: return "paintpalette.fill"
            case .pastel: return "cloud.fill"
            case .earth: return "leaf.fill"
            case .rainbow: return "rainbow"
            }
        }
    }

    enum AgeMode: String, CaseIterable, Identifiable {
        case kids = "Kids (4-8)"
        case family = "Family (8+)"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .kids: return "figure.child"
            case .family: return "figure.2.and.child.holdinghands"
            }
        }

        var description: String {
            switch self {
            case .kids: return "Larger regions, simpler images"
            case .family: return "More detailed images"
            }
        }
    }

    // MARK: - Init
    private init() {
        // Load saved settings or use defaults
        let paletteRaw = UserDefaults.standard.string(forKey: "colorPalette") ?? ColorPaletteType.vibrant.rawValue
        self.colorPalette = ColorPaletteType(rawValue: paletteRaw) ?? .vibrant

        let modeRaw = UserDefaults.standard.string(forKey: "ageMode") ?? AgeMode.kids.rawValue
        self.ageMode = AgeMode(rawValue: modeRaw) ?? .kids

        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.hapticEnabled = UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true
        self.showHints = UserDefaults.standard.object(forKey: "showHints") as? Bool ?? true
    }

    // MARK: - Helper
    var currentColors: [Color] {
        colorPalette.colors
    }

    func resetToDefaults() {
        colorPalette = .vibrant
        ageMode = .kids
        soundEnabled = true
        hapticEnabled = true
        showHints = true
    }
}

// MARK: - Color Palettes
extension Color {
    // Vibrant colors (current kid colors)
    static let vibrantColors: [Color] = [
        Color(red: 1.0, green: 0.4, blue: 0.4),   // Cherry
        Color(red: 1.0, green: 0.6, blue: 0.2),   // Tangerine
        Color(red: 1.0, green: 0.85, blue: 0.3),  // Sunshine
        Color(red: 0.6, green: 0.85, blue: 0.4),  // Lime
        Color(red: 0.2, green: 0.7, blue: 0.4),   // Grass
        Color(red: 0.2, green: 0.6, blue: 0.6),   // Ocean
        Color(red: 0.3, green: 0.6, blue: 0.9),   // Sky
        Color(red: 0.5, green: 0.4, blue: 0.8),   // Grape
        Color(red: 0.7, green: 0.3, blue: 0.6),   // Plum
        Color(red: 1.0, green: 0.5, blue: 0.7),   // Bubblegum
        Color(red: 0.5, green: 0.35, blue: 0.25), // Chocolate
        Color(red: 0.5, green: 0.55, blue: 0.6),  // Slate
    ]

    // Pastel colors - soft and gentle
    static let pastelColors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.8),   // Blush
        Color(red: 1.0, green: 0.9, blue: 0.75),  // Peach
        Color(red: 1.0, green: 1.0, blue: 0.8),   // Cream
        Color(red: 0.85, green: 1.0, blue: 0.85), // Mint
        Color(red: 0.75, green: 0.95, blue: 0.85),// Seafoam
        Color(red: 0.8, green: 0.9, blue: 1.0),   // Baby Blue
        Color(red: 0.85, green: 0.85, blue: 1.0), // Lavender
        Color(red: 0.95, green: 0.85, blue: 1.0), // Lilac
        Color(red: 1.0, green: 0.85, blue: 0.9),  // Rose
        Color(red: 0.9, green: 0.85, blue: 0.8),  // Sand
        Color(red: 0.85, green: 0.9, blue: 0.9),  // Powder
        Color(red: 0.95, green: 0.95, blue: 0.95),// Cloud
    ]

    // Earth tones - natural and warm
    static let earthColors: [Color] = [
        Color(red: 0.8, green: 0.5, blue: 0.3),   // Terracotta
        Color(red: 0.7, green: 0.45, blue: 0.25), // Rust
        Color(red: 0.85, green: 0.7, blue: 0.5),  // Tan
        Color(red: 0.6, green: 0.5, blue: 0.35),  // Olive
        Color(red: 0.4, green: 0.5, blue: 0.35),  // Moss
        Color(red: 0.35, green: 0.45, blue: 0.4), // Forest
        Color(red: 0.5, green: 0.6, blue: 0.55),  // Sage
        Color(red: 0.45, green: 0.35, blue: 0.3), // Coffee
        Color(red: 0.6, green: 0.55, blue: 0.5),  // Stone
        Color(red: 0.75, green: 0.65, blue: 0.55),// Wheat
        Color(red: 0.55, green: 0.45, blue: 0.4), // Clay
        Color(red: 0.4, green: 0.35, blue: 0.35), // Charcoal
    ]

    // Rainbow colors - classic spectrum
    static let rainbowColors: [Color] = [
        .red,
        Color(red: 1.0, green: 0.5, blue: 0.0),   // Orange
        .yellow,
        Color(red: 0.5, green: 1.0, blue: 0.0),   // Lime
        .green,
        Color(red: 0.0, green: 1.0, blue: 0.5),   // Spring
        .cyan,
        Color(red: 0.0, green: 0.5, blue: 1.0),   // Azure
        .blue,
        Color(red: 0.5, green: 0.0, blue: 1.0),   // Violet
        .purple,
        Color(red: 1.0, green: 0.0, blue: 0.5),   // Magenta
    ]
}
