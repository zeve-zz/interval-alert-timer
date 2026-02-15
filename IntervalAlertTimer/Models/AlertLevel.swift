import SwiftUI

enum AlertLevel: Int, CaseIterable, Comparable {
    case gentle
    case moderate
    case urgent
    case final_

    static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func forProgress(_ progress: Double) -> AlertLevel {
        switch progress {
        case ..<0.4: return .gentle
        case 0.4..<0.7: return .moderate
        case 0.7..<1.0: return .urgent
        default: return .final_
        }
    }

    var glowColor: Color {
        switch self {
        case .gentle: return .blue
        case .moderate: return .yellow
        case .urgent: return .orange
        case .final_: return .red
        }
    }

    var pulseDuration: Double {
        switch self {
        case .gentle: return 3.0
        case .moderate: return 2.0
        case .urgent: return 1.0
        case .final_: return 0.5
        }
    }

    var label: String {
        switch self {
        case .gentle: return "Gentle"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        case .final_: return "Final"
        }
    }
}
