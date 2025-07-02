import AVFoundation
import Sharing
import Dependencies

actor SoundPlayer {
    static let shared = SoundPlayer()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    @Shared(.appStorage("buttonSoundEnabled")) var buttonSoundEnabled: Bool = true
    
    private init() {}
    
    func play(soundNamed name: String) async {
        guard buttonSoundEnabled else { return }
        if let player = players[name] {
            player.currentTime = 0
            player.play()
        } else if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[name] = player
                player.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
    }
    
    func playCheckinSound() async {
        await play(soundNamed: "checkin_sound")
    }
    
    func playCancelCheckinSound() async {
        await play(soundNamed: "cancel_checkin")
    }
}

extension DependencyValues {
    var soundPlayer: SoundPlayer {
        get { self[SoundPlayerKey.self] }
        set { self[SoundPlayerKey.self] = newValue }
    }
}

private enum SoundPlayerKey: DependencyKey {
    static let liveValue = SoundPlayer.shared
}
