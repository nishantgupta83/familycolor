import Foundation

/// Registry for discovering and managing available line art engines
/// Provides fallback logic when requested engine is unavailable
final class EngineRegistry {
    /// Shared instance
    static let shared = EngineRegistry()

    // MARK: - Private Properties

    /// Cached engine instances (lazy-loaded)
    private var cachedEngines: [EngineType: any LineArtExtractorProtocol] = [:]

    /// Lock for thread-safe access
    private let lock = NSLock()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Get an engine instance for the given type
    /// - Parameter type: The engine type to get
    /// - Returns: The engine if available, nil otherwise
    func engine(for type: EngineType) -> (any LineArtExtractorProtocol)? {
        lock.lock()
        defer { lock.unlock() }

        // Return cached if available
        if let cached = cachedEngines[type] {
            return cached
        }

        // Create and cache new instance
        let engine = createEngine(for: type)
        if let engine = engine, engine.isAvailable {
            cachedEngines[type] = engine
            return engine
        }

        return nil
    }

    /// Resolve requested engine to an available engine (with fallback)
    /// - Parameter requested: The engine type requested by user
    /// - Returns: The resolved engine type (may be different if fallback needed)
    func resolveEngine(requested: EngineType) -> EngineType {
        if isAvailable(requested) {
            return requested
        }
        // Always fallback to Vision (guaranteed available)
        return .vision
    }

    /// Get all available engines
    /// - Returns: Array of available engine types
    func availableEngines() -> [EngineType] {
        EngineType.allCases.filter { isAvailable($0) }
    }

    /// Check if an engine is available
    /// - Parameter type: The engine type to check
    /// - Returns: True if the engine is available
    func isAvailable(_ type: EngineType) -> Bool {
        switch type {
        case .vision:
            // Vision framework is always available on iOS 14+
            return true
        case .hed:
            // HED requires the CoreML model to be loaded
            return engine(for: .hed)?.isAvailable ?? false
        }
    }

    /// Pre-load an engine for fast first use
    /// - Parameter type: The engine type to warm up
    func warmUp(_ type: EngineType) async {
        // Access the engine to trigger lazy loading
        _ = engine(for: type)
    }

    /// Clear cached engines (useful for testing)
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedEngines.removeAll()
    }

    // MARK: - Private Methods

    private func createEngine(for type: EngineType) -> (any LineArtExtractorProtocol)? {
        switch type {
        case .vision:
            return VisionExtractorAdapter()
        case .hed:
            return HEDEngine()
        }
    }
}

// MARK: - Engine Type Extensions

extension EngineType {
    /// Display name for UI
    var displayName: String {
        switch self {
        case .vision: return "Standard"
        case .hed: return "Deep Edges"
        }
    }

    /// Icon for UI (SF Symbol name)
    var iconName: String {
        switch self {
        case .vision: return "eye.fill"
        case .hed: return "brain.head.profile"
        }
    }

    /// Description for UI tooltips
    var description: String {
        switch self {
        case .vision:
            return "Fast edge detection using Apple Vision framework"
        case .hed:
            return "Deep learning edge detection for cleaner, more consistent edges"
        }
    }
}
