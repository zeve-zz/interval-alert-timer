import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    // Static data — set once when the activity starts
    var totalDuration: TimeInterval
    var intervalModeLabel: String

    struct ContentState: Codable, Hashable {
        var alertLevelRaw: Int      // AlertLevel.rawValue
        var isPaused: Bool
        var isComplete: Bool
        var endDate: Date           // when the timer will hit zero (shifts on pause/resume)
        var progress: Double        // 0.0 … 1.0
        var remainingLabel: String  // e.g. "4:32" — compact, no width reservation
    }
}
