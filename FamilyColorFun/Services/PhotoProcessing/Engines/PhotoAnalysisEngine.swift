import UIKit
@preconcurrency import Vision

/// Vision-based photo analysis engine
/// Analyzes photos to suggest appropriate presets and engines
final class PhotoAnalysisEngine {

    // MARK: - Data Types

    /// Analysis result with policy decisions
    struct Analysis {
        let subjects: [String]
        let confidence: Float
        let detectedFacesCount: Int
        let isLikelyPortrait: Bool
        let suggestedPreset: LineArtPreset
        let suggestedEngine: EngineType
        let recommendedParameters: ParameterOverrides
        let reasons: [String]
    }

    /// Parameter overrides based on analysis
    struct ParameterOverrides {
        let thresholdAdjustment: Float?
        let lineThicknessOverride: Int?
        let minRegionAreaOverride: Int?

        static let none = ParameterOverrides(
            thresholdAdjustment: nil,
            lineThicknessOverride: nil,
            minRegionAreaOverride: nil
        )
    }

    // MARK: - Public API

    /// Analyze a photo and return suggestions
    func analyze(photo: UIImage) async throws -> Analysis {
        guard let cgImage = photo.cgImage else {
            throw ProcessingError.photoLoadFailed("Could not get CGImage")
        }

        // Run analysis tasks in parallel
        async let faceResult = detectFaces(in: cgImage)
        async let classificationResult = classifyImage(cgImage)

        let (faces, classifications) = try await (faceResult, classificationResult)

        // Determine suggestions based on detections
        return mapToSuggestions(faces: faces, classifications: classifications)
    }

    // MARK: - Face Detection

    private func detectFaces(in image: CGImage) async throws -> [VNFaceObservation] {
        let request = VNDetectFaceRectanglesRequest()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let results = request.results ?? []
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(returning: [])  // Non-critical, return empty
                }
            }
        }
    }

    // MARK: - Image Classification

    private func classifyImage(_ image: CGImage) async throws -> [VNClassificationObservation] {
        let request = VNClassifyImageRequest()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let results = request.results ?? []
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(returning: [])  // Non-critical, return empty
                }
            }
        }
    }

    // MARK: - Mapping Rules

    private func mapToSuggestions(
        faces: [VNFaceObservation],
        classifications: [VNClassificationObservation]
    ) -> Analysis {
        var reasons: [String] = []
        var subjects: [String] = []

        // Extract top classifications
        let topClassifications = classifications
            .filter { $0.confidence > 0.1 }
            .prefix(5)

        for classification in topClassifications {
            subjects.append(classification.identifier)
        }

        // Check face detection
        let faceCount = faces.count
        let totalFaceArea = faces.reduce(0.0) { sum, face in
            sum + (face.boundingBox.width * face.boundingBox.height)
        }
        let isLikelyPortrait = faceCount > 0 && totalFaceArea > 0.1

        // Determine preset and engine based on rules
        var suggestedPreset: LineArtPreset = .object
        var suggestedEngine: EngineType = .vision
        var overrides = ParameterOverrides.none

        // Rule 1: Face detected with significant area -> portrait
        if isLikelyPortrait {
            suggestedPreset = .portrait
            suggestedEngine = .hed
            reasons.append("Face detected (\(faceCount)) -> portrait preset with HED")
        }
        // Rule 2: Animal classification -> pet preset
        else if containsAnimalClass(subjects) {
            suggestedPreset = .pet
            suggestedEngine = .vision
            reasons.append("Animal detected -> pet preset")
        }
        // Rule 3: Outdoor/landscape classification -> landscape preset
        else if containsLandscapeClass(subjects) {
            suggestedPreset = .landscape
            suggestedEngine = .vision
            reasons.append("Landscape/outdoor detected -> landscape preset")
        }
        // Rule 4: Check for high texture scenes
        else if containsHighTextureClass(subjects) {
            suggestedPreset = .toddler
            suggestedEngine = .vision
            overrides = ParameterOverrides(
                thresholdAdjustment: 0.2,
                lineThicknessOverride: nil,
                minRegionAreaOverride: nil
            )
            reasons.append("High texture scene -> simplified output")
        }

        // Default reason if no specific match
        if reasons.isEmpty {
            reasons.append("Default -> object preset")
        }

        let avgConfidence = topClassifications.isEmpty ? 0.0 :
            topClassifications.reduce(0.0) { $0 + $1.confidence } / Float(topClassifications.count)

        return Analysis(
            subjects: subjects,
            confidence: avgConfidence,
            detectedFacesCount: faceCount,
            isLikelyPortrait: isLikelyPortrait,
            suggestedPreset: suggestedPreset,
            suggestedEngine: suggestedEngine,
            recommendedParameters: overrides,
            reasons: reasons
        )
    }

    // MARK: - Classification Helpers

    private func containsAnimalClass(_ subjects: [String]) -> Bool {
        let animalKeywords = ["dog", "cat", "pet", "animal", "bird", "fish", "horse",
                              "cow", "sheep", "rabbit", "hamster", "puppy", "kitten"]
        return subjects.contains { subject in
            animalKeywords.contains { keyword in
                subject.lowercased().contains(keyword)
            }
        }
    }

    private func containsLandscapeClass(_ subjects: [String]) -> Bool {
        let landscapeKeywords = ["landscape", "outdoor", "mountain", "beach", "forest",
                                 "sky", "ocean", "lake", "river", "park", "garden", "nature"]
        return subjects.contains { subject in
            landscapeKeywords.contains { keyword in
                subject.lowercased().contains(keyword)
            }
        }
    }

    private func containsHighTextureClass(_ subjects: [String]) -> Bool {
        let textureKeywords = ["grass", "foliage", "texture", "pattern", "fabric",
                               "hair", "fur", "feather", "leaves"]
        return subjects.contains { subject in
            textureKeywords.contains { keyword in
                subject.lowercased().contains(keyword)
            }
        }
    }
}
