import Foundation

struct TimerPreset: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var configuration: TimerConfiguration
    var isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, configuration: TimerConfiguration, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.configuration = configuration
        self.isBuiltIn = isBuiltIn
    }

    static let builtInPresets: [TimerPreset] = [
        TimerPreset(
            name: "Quick Shower",
            configuration: TimerConfiguration(totalDuration: 300, intervalMode: .percentage(25)),
            isBuiltIn: true
        ),
        TimerPreset(
            name: "Workout Set",
            configuration: TimerConfiguration(totalDuration: 180, intervalMode: .fixedTime(60)),
            isBuiltIn: true
        ),
        TimerPreset(
            name: "Focus Block",
            configuration: TimerConfiguration(totalDuration: 1500, intervalMode: .percentage(25)),
            isBuiltIn: true
        ),
    ]
}
