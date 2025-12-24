import UIKit

/// Final result of the complete line art pipeline
/// Contains all outputs and metadata for debugging/display
struct LineArtResult: Equatable {
    /// Final line art image ready for coloring
    let lineArt: UIImage

    /// Fillability validation results
    let fillability: FillabilityResult

    /// Intermediate output from post-processor
    let intermediate: LineArtIntermediate

    /// Raw edge map from engine (for debugging/preview)
    let edgeMap: EdgeMap

    /// Run ID to prevent stale updates
    let runID: UUID

    /// Total processing time in milliseconds
    var totalProcessingTimeMs: Int {
        edgeMap.engineMeta.processingTimeMs
    }

    /// Engine that produced this result
    var engineName: String {
        edgeMap.engineMeta.engineName
    }
}

extension LineArtResult {
    /// Create a summary string for debugging/logging
    var summary: String {
        """
        LineArtResult (\(runID.uuidString.prefix(8))):
          Engine: \(engineName)
          Time: \(totalProcessingTimeMs)ms
          Regions: \(intermediate.regionEstimate)
          Quality: \(fillability.quality.message)
          Score: \(String(format: "%.2f", fillability.score))
        """
    }
}

// MARK: - Equatable conformance for FillabilityResult
extension FillabilityResult: Equatable {
    static func == (lhs: FillabilityResult, rhs: FillabilityResult) -> Bool {
        lhs.score == rhs.score &&
        lhs.regionCount == rhs.regionCount &&
        lhs.closureRate == rhs.closureRate &&
        lhs.leakPotential == rhs.leakPotential &&
        lhs.tapUsability == rhs.tapUsability
    }
}
