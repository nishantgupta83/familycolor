import Foundation
import Combine

// MARK: - Engine Type

/// Available line art extraction engines
enum EngineType: String, CaseIterable, Codable, Hashable {
    case vision  // Apple Vision framework (always available)
    case hed     // HED deep edge detection (requires CoreML model)
}

// MARK: - Processing Phase

/// Hashable phase for state transition table
/// No associated values - used as dictionary keys
enum ProcessingPhase: String, Hashable, CaseIterable {
    case idle
    case loadingPhoto
    case preprocessing
    case extractingLines
    case postProcessing
    case validating
    case analyzing
    case complete
    case failed
    case cancelling
    case cancelled
}

// MARK: - Processing Error

/// Errors that can occur during photo processing
enum ProcessingError: Error, Equatable {
    case photoLoadFailed(String)
    case preprocessingFailed(String)
    case engineNotAvailable(EngineType)
    case extractionFailed(String)
    case postProcessingFailed(String)
    case validationFailed(String)
    case cancelled
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .photoLoadFailed(let msg): return "Failed to load photo: \(msg)"
        case .preprocessingFailed(let msg): return "Preprocessing failed: \(msg)"
        case .engineNotAvailable(let type): return "Engine not available: \(type.rawValue)"
        case .extractionFailed(let msg): return "Edge extraction failed: \(msg)"
        case .postProcessingFailed(let msg): return "Post-processing failed: \(msg)"
        case .validationFailed(let msg): return "Validation failed: \(msg)"
        case .cancelled: return "Processing was cancelled"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
}

// MARK: - Processing State

/// Rich state with associated values for progress and results
enum ProcessingState: Equatable {
    case idle
    case loadingPhoto
    case preprocessing(progress: Float)
    case extractingLines(resolvedEngine: EngineType, progress: Float)
    case postProcessing
    case validating
    case analyzing
    case complete(result: LineArtResult)
    case failed(error: ProcessingError)
    case cancelling
    case cancelled

    /// Extract the phase for transition table lookup
    var phase: ProcessingPhase {
        switch self {
        case .idle: return .idle
        case .loadingPhoto: return .loadingPhoto
        case .preprocessing: return .preprocessing
        case .extractingLines: return .extractingLines
        case .postProcessing: return .postProcessing
        case .validating: return .validating
        case .analyzing: return .analyzing
        case .complete: return .complete
        case .failed: return .failed
        case .cancelling: return .cancelling
        case .cancelled: return .cancelled
        }
    }

    /// Progress value (0.0-1.0) if available
    var progress: Float? {
        switch self {
        case .preprocessing(let p), .extractingLines(_, let p):
            return p
        default:
            return nil
        }
    }

    /// Whether processing is in progress
    var isProcessing: Bool {
        switch self {
        case .loadingPhoto, .preprocessing, .extractingLines, .postProcessing, .validating, .analyzing:
            return true
        default:
            return false
        }
    }

    /// Whether processing completed successfully
    var isComplete: Bool {
        if case .complete = self { return true }
        return false
    }

    /// Whether processing failed
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

// MARK: - Processing State Manager

/// Manages state transitions with explicit rules and stale update prevention
final class ProcessingStateManager: ObservableObject {
    /// Current processing state
    @Published private(set) var state: ProcessingState = .idle

    /// Current run identifier (prevents stale async updates)
    @Published private(set) var runID: UUID = UUID()

    /// History of phases for debugging
    @Published private(set) var history: [ProcessingPhase] = []

    /// Explicit transition table: [fromPhase: Set<toPhase>]
    private let transitions: [ProcessingPhase: Set<ProcessingPhase>] = [
        .idle: [.loadingPhoto],
        .loadingPhoto: [.preprocessing, .failed, .cancelling],
        .preprocessing: [.extractingLines, .failed, .cancelling],
        .extractingLines: [.postProcessing, .preprocessing, .failed, .cancelling],
        .postProcessing: [.validating, .failed, .cancelling],
        .validating: [.analyzing, .complete, .failed, .cancelling],
        .analyzing: [.complete, .failed, .cancelling],
        .complete: [.idle, .extractingLines],  // extractingLines = reprocess
        .failed: [.idle],
        .cancelling: [.cancelled],
        .cancelled: [.idle]
    ]

    // MARK: - Public API

    /// Check if a transition to the given phase is allowed
    func canTransition(to newPhase: ProcessingPhase) -> Bool {
        transitions[state.phase]?.contains(newPhase) ?? false
    }

    /// Attempt to transition to a new state
    /// - Parameters:
    ///   - newState: The state to transition to
    ///   - forRun: The run ID this transition belongs to (prevents stale updates)
    /// - Returns: True if transition succeeded, false if rejected
    @discardableResult
    func transition(to newState: ProcessingState, forRun: UUID) -> Bool {
        // Reject stale updates from previous runs
        guard forRun == runID else {
            return false
        }

        // Validate transition is allowed
        guard canTransition(to: newState.phase) else {
            return false
        }

        // Record history and update state
        history.append(state.phase)
        state = newState
        return true
    }

    /// Start a new processing run
    /// - Returns: The new run ID
    @discardableResult
    func newRun() -> UUID {
        runID = UUID()
        history = []
        state = .idle
        return runID
    }

    /// Reset to idle state
    func reset() {
        state = .idle
        history = []
    }

    /// Get the current run ID (for passing to async operations)
    var currentRunID: UUID { runID }
}
