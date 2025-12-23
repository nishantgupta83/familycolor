import Foundation

/// Result of fillability validation with score and suggestions
struct FillabilityResult {
    let score: Double           // 0.0 - 1.0
    let regionCount: Int
    let closureRate: Double     // % of regions fully enclosed
    let leakPotential: Double   // 0.0 (good) - 1.0 (leaky)
    let tapUsability: Double    // % of regions large enough to tap
    let suggestions: [String]

    /// Overall quality assessment
    var quality: Quality {
        if score >= 0.85 { return .good }
        if score >= 0.6 { return .okay }
        return .poor
    }

    enum Quality {
        case good   // Ready to color
        case okay   // Some areas may not fill perfectly
        case poor   // Try different settings

        var message: String {
            switch self {
            case .good: return "Great! Ready to color"
            case .okay: return "Okay - some areas may not fill perfectly"
            case .poor: return "Try different settings"
            }
        }
    }
}

extension FillabilityResult {
    /// Create a result indicating validation was skipped
    static var skipped: FillabilityResult {
        FillabilityResult(
            score: 1.0,
            regionCount: 0,
            closureRate: 1.0,
            leakPotential: 0.0,
            tapUsability: 1.0,
            suggestions: []
        )
    }
}
