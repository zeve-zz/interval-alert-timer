import Foundation

enum IntervalMode: Codable, Hashable {
    case percentage(Int)
    case fixedTime(TimeInterval)

    var displayLabel: String {
        switch self {
        case .percentage(let pct): return "Every \(pct)%"
        case .fixedTime(let secs):
            let mins = Int(secs) / 60
            let sec = Int(secs) % 60
            if mins > 0 && sec > 0 { return "Every \(mins)m \(sec)s" }
            if mins > 0 { return "Every \(mins)m" }
            return "Every \(sec)s"
        }
    }
}

struct TimerConfiguration: Codable, Hashable {
    var totalDuration: TimeInterval
    var intervalMode: IntervalMode

    var alertOffsets: [TimeInterval] {
        var offsets: [TimeInterval] = []
        switch intervalMode {
        case .percentage(let pct):
            guard pct > 0, pct <= 100 else { return [totalDuration] }
            let step = totalDuration * Double(pct) / 100.0
            var t = step
            while t < totalDuration {
                offsets.append(t)
                t += step
            }
        case .fixedTime(let interval):
            guard interval > 0 else { return [totalDuration] }
            var t = interval
            while t < totalDuration {
                offsets.append(t)
                t += interval
            }
        }
        offsets.append(totalDuration)
        return offsets
    }

    var alertCount: Int { alertOffsets.count }
}
