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
        case .gentle: return Color(hex: 0x8AABA0)    // Soft teal
        case .moderate: return Color(hex: 0xC4A882)   // Warm sand
        case .urgent: return Color(hex: 0xC48B6E)     // Terracotta
        case .final_: return Color(hex: 0xB87272)     // Dusty rose
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
