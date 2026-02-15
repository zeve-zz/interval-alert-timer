import UIKit

struct HapticService {
    func fire(count: Int) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        for i in 1..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                generator.impactOccurred()
            }
        }
    }
}
