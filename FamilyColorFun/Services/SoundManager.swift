import AVFoundation
import SwiftUI

class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "sound_muted")
        }
    }

    private var tapPlayer: AVAudioPlayer?
    private var fillPlayer: AVAudioPlayer?
    private var celebrationPlayer: AVAudioPlayer?

    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "sound_muted")
        setupPlayers()
    }

    private func setupPlayers() {
        // Using system sounds as placeholders until custom sounds are added
        // In production, load from bundle: Bundle.main.url(forResource: "tap", withExtension: "mp3")
    }

    func playTap() {
        guard !isMuted else { return }

        // System haptic as audio feedback placeholder
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Play system sound
        AudioServicesPlaySystemSound(1104) // Tock sound
    }

    func playFill() {
        guard !isMuted else { return }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        AudioServicesPlaySystemSound(1306) // Pop sound
    }

    func playCelebration() {
        guard !isMuted else { return }

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Play multiple sounds for celebration effect
        AudioServicesPlaySystemSound(1025) // Celebration-like sound

        // Delayed second sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard self != nil else { return }
            AudioServicesPlaySystemSound(1026)
        }
    }

    func toggleMute() {
        isMuted.toggle()
    }
}
