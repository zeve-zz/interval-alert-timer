import AudioToolbox
import AVFoundation

struct AudioService {
    func fire(count: Int) {
        AudioServicesPlaySystemSound(1057)
        for i in 1..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                AudioServicesPlaySystemSound(1057)
            }
        }
    }

    func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
