import UserNotifications

struct NotificationService: Sendable {
    private let categoryID = "TIMER_ALERT"

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleAlerts(for config: TimerConfiguration, startDate: Date, elapsed: TimeInterval = 0) {
        let center = UNUserNotificationCenter.current()
        let offsets = config.alertOffsets
        for (index, offset) in offsets.enumerated() {
            let fireIn = offset - elapsed
            guard fireIn > 0 else { continue }

            let alertProgress = offset / config.totalDuration
            let level = AlertLevel.forProgress(alertProgress)
            let isFinal = offset >= config.totalDuration

            let content = UNMutableNotificationContent()
            content.title = isFinal ? "Timer Complete!" : "Interval Alert"
            content.body = isFinal
                ? "Your \(formatDuration(config.totalDuration)) timer has ended."
                : "\(level.label) — \(Int(alertProgress * 100))% elapsed"
            content.sound = soundForLevel(level)
            content.categoryIdentifier = categoryID

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireIn, repeats: false)
            let request = UNNotificationRequest(
                identifier: "timer-alert-\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func soundForLevel(_ level: AlertLevel) -> UNNotificationSound {
        .default
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        if mins > 0 { return "\(mins) min" }
        return "\(Int(t))s"
    }
}
