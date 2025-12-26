import SwiftUI

// MARK: - Suggestion Mode

enum ColorSuggestionMode: String, CaseIterable, Identifiable {
    case realistic = "Realistic"
    case creative = "Creative"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .realistic: return "paintbrush.pointed.fill"
        case .creative: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .realistic: return "Suggests real-world colors"
        case .creative: return "Random fun colors"
        }
    }
}

// MARK: - Color Suggestion

struct ColorSuggestion: Identifiable {
    let id = UUID()
    let regionId: Int
    let suggestedColor: Color
    let paletteIndex: Int
    let centroid: CGPoint
    let boundingBox: CGRect
}

// MARK: - Subject Color Mapping

/// Maps keywords found in page names to realistic color palette indices
struct SubjectColorMap {

    /// Keyword → palette indices mapping for realistic suggestions
    /// Uses palette indices (0-11) from current palette
    static let keywordColors: [String: [Int]] = [
        // Animals
        "lion": [1, 2, 10],           // orange, yellow, brown
        "elephant": [11, 6],          // gray, sky blue
        "bunny": [9, 0, 11],          // pink, white-ish, gray
        "rabbit": [9, 0, 11],
        "cat": [1, 10, 11],           // orange, brown, gray
        "fox": [1, 0, 10],            // orange, red, brown
        "panda": [11, 0],             // black/gray, white
        "giraffe": [2, 10, 1],        // yellow, brown, orange
        "koala": [11, 10],            // gray, brown
        "penguin": [11, 0, 1],        // black, white, orange (beak)
        "dog": [10, 1, 11],           // brown, orange, gray
        "turtle": [4, 10, 3],         // green, brown, lime
        "owl": [10, 1, 11],           // brown, orange, gray
        "horse": [10, 0, 11],         // brown, white, gray

        // Ocean/Underwater
        "dolphin": [6, 5, 11],        // sky, ocean, gray
        "whale": [6, 5, 11],
        "fish": [6, 5, 1, 9],         // blue, ocean, orange, pink
        "clownfish": [1, 0],          // orange, white
        "angelfish": [2, 6, 9],       // yellow, blue, pink
        "pufferfish": [2, 6],         // yellow, blue
        "betafish": [7, 0, 6],        // purple, red, blue
        "seahorse": [7, 9, 1],        // purple, pink, orange
        "octopus": [7, 8, 9],         // purple, plum, pink
        "shark": [11, 5],             // gray, ocean
        "lobster": [0, 1],            // red, orange

        // Dinosaurs
        "dino": [4, 3, 7],            // green, lime, purple
        "dinosaur": [4, 3, 7],
        "trex": [4, 10, 3],           // green, brown, lime
        "triceratops": [4, 6, 3],     // green, blue, lime
        "flying": [6, 4, 7],          // blue, green, purple

        // Fantasy
        "unicorn": [9, 7, 6],         // pink, purple, sky
        "mermaid": [5, 9, 7],         // ocean, pink, purple
        "fairy": [9, 7, 3],           // pink, purple, lime
        "princess": [9, 7, 2],        // pink, purple, yellow

        // Vehicles
        "car": [0, 6, 2],             // red, blue, yellow
        "truck": [0, 6, 1],           // red, blue, orange
        "train": [0, 6, 11],          // red, blue, gray
        "airplane": [6, 0, 11],       // blue, red, gray
        "boat": [0, 6, 10],           // red, blue, brown
        "sailboat": [0, 6, 10],
        "tractor": [4, 0, 2],         // green, red, yellow
        "police": [6, 0],             // blue, red
        "race": [0, 2, 6],            // red, yellow, blue
        "puppy": [10, 1, 11],         // brown, orange, gray

        // Houses
        "house": [0, 10, 4],          // red (roof), brown, green (grass)
        "cozy": [10, 0, 4],           // brown, red, green
        "gingerbread": [10, 0, 9],    // brown, red, pink
        "cottage": [10, 4, 6],        // brown, green, blue
        "haunted": [7, 11, 1],        // purple, gray, orange
        "halloween": [1, 7, 11],      // orange, purple, black
        "chimney": [11, 10, 0],       // gray, brown, red
        "garden": [4, 9, 2],          // green, pink, yellow

        // Nature
        "rainbow": [0, 1, 2, 3, 4, 6, 7], // full spectrum
        "sunflower": [2, 10, 4],      // yellow, brown, green
        "daisy": [0, 2, 4],           // white/red center, yellow, green
        "rose": [0, 9, 4],            // red, pink, green
        "tulip": [0, 9, 2, 4],        // red, pink, yellow, green
        "lily": [9, 4, 2],            // pink, green, yellow
        "tree": [4, 10, 3],           // green, brown, lime
        "mountains": [11, 6, 4],      // gray, blue, green
        "waterfall": [6, 5, 4],       // blue, ocean, green
        "butterfly": [9, 7, 1, 6],    // pink, purple, orange, blue
        "sky": [6, 5],                // sky blue, ocean
        "sun": [2, 1],                // yellow, orange
        "cloud": [11, 6],             // white/gray, light blue
        "balloons": [0, 2, 6, 9],     // red, yellow, blue, pink
        "night": [7, 6, 2],           // purple, blue, yellow (stars)

        // Holidays
        "christmas": [0, 4, 2],       // red, green, yellow/gold
        "snowman": [11, 1, 0],        // white, orange (carrot), red (scarf)
        "cocoa": [10, 0, 11],         // brown, red, white
        "valentine": [0, 9],          // red, pink
        "birthday": [9, 7, 2, 6],     // pink, purple, yellow, blue
        "mother": [9, 0, 4],          // pink, red, green
        "flower": [9, 0, 7, 2],       // pink, red, purple, yellow
    ]

    /// Category-level default colors when no keyword matches
    static let categoryDefaults: [String: [Int]] = [
        "animals": [10, 1, 4, 11],        // brown, orange, green, gray
        "vehicles": [0, 6, 2, 11],        // red, blue, yellow, gray
        "houses": [0, 10, 4, 6],          // red, brown, green, blue
        "nature": [4, 3, 2, 6, 9],        // greens, yellow, blue, pink
        "ocean": [6, 5, 11, 9],           // blues, gray, pink
        "underwater": [6, 5, 4, 7],       // blues, green, purple
        "dinosaurs": [4, 3, 10, 7],       // greens, brown, purple
        "fantasy": [9, 7, 6, 2],          // pink, purple, blue, yellow
        "holidays": [0, 4, 2, 9],         // red, green, yellow, pink
    ]

    /// Find matching color indices for a page name and category
    static func colorsFor(pageName: String, categoryId: String) -> [Int] {
        let lowercaseName = pageName.lowercased()

        // Try to find keyword matches (check all keywords)
        for (keyword, colors) in keywordColors {
            if lowercaseName.contains(keyword) {
                return colors.shuffled()
            }
        }

        // Fallback to category defaults
        return categoryDefaults[categoryId]?.shuffled() ?? [0, 1, 2, 3]
    }
}
