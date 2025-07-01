import AVFoundation

struct SoundPlayer {
    static var player: AVAudioPlayer?
    static func playCheckinSound() {
        guard UserDefaults.standard.bool(forKey: "buttonSoundEnabled") else { return }
        guard let url = Bundle.main.url(forResource: "checkin_sound", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
} 