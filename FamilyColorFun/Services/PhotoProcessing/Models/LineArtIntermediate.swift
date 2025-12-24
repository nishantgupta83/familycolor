import UIKit

/// Output from the LineArtPostProcessor
/// Contains the final line art image plus metadata about processing
struct LineArtIntermediate: Equatable {
    /// Final black/white line art image ready for coloring
    let lineImage: UIImage

    /// Actual line thickness in pixels after dilation
    let lineThickness: Int

    /// Estimated region count (computed AFTER close, BEFORE dilation)
    /// Reflects actual region structure, not thickness artifacts
    let regionEstimate: Int

    /// List of post-processing operations applied
    /// e.g., ["binarize(0.5)", "close(3)", "dilate(2)", "removeSpeckles(30)"]
    let postProcessingApplied: [String]

    /// Whether toddler simplification was applied
    var isSimplified: Bool {
        postProcessingApplied.contains { $0.hasPrefix("simplify") }
    }
}

extension LineArtIntermediate {
    /// Create a summary string for debugging/logging
    var summary: String {
        "LineArt: \(lineThickness)px thick, ~\(regionEstimate) regions, ops: \(postProcessingApplied.joined(separator: ", "))"
    }
}
