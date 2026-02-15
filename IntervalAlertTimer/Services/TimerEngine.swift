import Foundation
import Observation
import SwiftUI

@Observable
final class TimerEngine {
    // MARK: - Published State
    var remainingTime: TimeInterval = 0
    var progress: Double = 0
    var isRunning = false
    var isPaused = false
    var currentAlertLevel: AlertLevel = .gentle
    var firedAlertIndices: Set<Int> = []
    var latestFiredLevel: AlertLevel?
    var isDismissing = false

    // MARK: - Configuration
    private(set) var configuration: TimerConfiguration?

    // MARK: - Internal Timing
    private var startDate: Date?
    private var pauseDate: Date?
    private var accumulatedPauseTime: TimeInterval = 0
    private var displayTimer: Timer?

    // MARK: - Services
    var onAlertFired: ((AlertLevel, Int) -> Void)?

    // MARK: - Computed
    var elapsed: TimeInterval {
        guard let start = startDate else { return 0 }
        let pauseAdjust = isPaused ? (pauseDate.map { Date().timeIntervalSince($0) } ?? 0) : 0
        return Date().timeIntervalSince(start) - accumulatedPauseTime - pauseAdjust
    }

    var isComplete: Bool { progress >= 1.0 }

    // MARK: - Actions

    func start(with config: TimerConfiguration) {
        configuration = config
        startDate = Date()
        pauseDate = nil
        accumulatedPauseTime = 0
        firedAlertIndices = []
        latestFiredLevel = nil
        isRunning = true
        isPaused = false
        tick()
        startDisplayTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pauseDate = Date()
        stopDisplayTimer()
    }

    func resume() {
        guard isRunning, isPaused, let pd = pauseDate else { return }
        accumulatedPauseTime += Date().timeIntervalSince(pd)
        pauseDate = nil
        isPaused = false
        tick()
        startDisplayTimer()
    }

    func cancel() {
        isRunning = false
        isPaused = false
        isDismissing = false
        stopDisplayTimer()
        startDate = nil
        pauseDate = nil
        accumulatedPauseTime = 0
        remainingTime = 0
        progress = 0
        firedAlertIndices = []
        latestFiredLevel = nil
        currentAlertLevel = .gentle
    }

    func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        stopDisplayTimer()

        let startProgress = progress
        let dismissDuration: TimeInterval = 0.5
        let dismissStart = Date()

        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = Date().timeIntervalSince(dismissStart)
            let t = min(elapsed / dismissDuration, 1.0)
            let eased = 1 - (1 - t) * (1 - t)
            self.progress = startProgress * (1 - eased)

            if t >= 1.0 {
                timer.invalidate()
                self.cancel()
            }
        }
    }

    func recalculateFromDate() {
        guard isRunning, !isPaused else { return }
        tick()
    }

    // MARK: - Tick

    func tick() {
        guard let config = configuration, isRunning, !isPaused else { return }

        let el = elapsed
        let total = config.totalDuration
        let remaining = max(total - el, 0)

        remainingTime = remaining
        progress = min(el / total, 1.0)
        currentAlertLevel = AlertLevel.forProgress(progress)

        let offsets = config.alertOffsets
        for (index, offset) in offsets.enumerated() {
            if el >= offset && !firedAlertIndices.contains(index) {
                firedAlertIndices.insert(index)
                let alertProgress = offset / total
                let level = AlertLevel.forProgress(alertProgress)
                latestFiredLevel = level
                onAlertFired?(level, index)
            }
        }

        if remaining <= 0 {
            isRunning = false
            isPaused = false
            stopDisplayTimer()
            progress = 1.0
            remainingTime = 0
        }
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    // MARK: - Formatting

    static func formatTime(_ interval: TimeInterval) -> String {
        let total = max(Int(ceil(interval)), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
