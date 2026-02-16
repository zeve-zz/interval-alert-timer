import ActivityKit
import Foundation
import Observation
import SwiftUI

@MainActor @Observable
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
    private var lastLiveActivityUpdate: Date?

    // MARK: - Live Activity
    private var currentActivity: Activity<TimerActivityAttributes>?
    private var lastReportedAlertLevel: AlertLevel?

    // MARK: - Services
    var onAlertFired: ((AlertLevel, Int) -> Void)?

    // MARK: - Computed
    var elapsed: TimeInterval {
        guard let start = startDate else { return 0 }
        let pauseAdjust = isPaused ? (pauseDate.map { Date().timeIntervalSince($0) } ?? 0) : 0
        return Date().timeIntervalSince(start) - accumulatedPauseTime - pauseAdjust
    }

    var isComplete: Bool { progress >= 1.0 }

    /// The Date when the timer will reach zero, assuming it keeps running from now.
    var endDate: Date {
        Date().addingTimeInterval(remainingTime)
    }

    // MARK: - Actions

    func start(with config: TimerConfiguration) {
        configuration = config
        startDate = Date()
        pauseDate = nil
        accumulatedPauseTime = 0
        firedAlertIndices = []
        latestFiredLevel = nil
        lastReportedAlertLevel = nil
        isRunning = true
        isPaused = false
        tick()
        startDisplayTimer()
        startLiveActivity()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pauseDate = Date()
        stopDisplayTimer()
        updateLiveActivity()
    }

    func resume() {
        guard isRunning, isPaused, let pd = pauseDate else { return }
        accumulatedPauseTime += Date().timeIntervalSince(pd)
        pauseDate = nil
        isPaused = false
        tick()
        startDisplayTimer()
        updateLiveActivity()
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
        lastReportedAlertLevel = nil
        lastLiveActivityUpdate = nil
        currentAlertLevel = .gentle
        endLiveActivity(showComplete: false)
    }

    func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        stopDisplayTimer()
        endLiveActivity(showComplete: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
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

        // Update live activity when alert level changes or every 5s for the compact countdown
        let now = Date()
        let needsPeriodicUpdate = lastLiveActivityUpdate.map { now.timeIntervalSince($0) >= 5 } ?? true
        if currentAlertLevel != lastReportedAlertLevel || needsPeriodicUpdate {
            lastReportedAlertLevel = currentAlertLevel
            lastLiveActivityUpdate = now
            updateLiveActivity()
        }

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
            endLiveActivity(showComplete: true)
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

    // MARK: - Live Activity

    func startLiveActivity() {
        guard let config = configuration else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = TimerActivityAttributes(
            totalDuration: config.totalDuration,
            intervalModeLabel: config.intervalMode.displayLabel
        )

        let state = TimerActivityAttributes.ContentState(
            alertLevelRaw: currentAlertLevel.rawValue,
            isPaused: isPaused,
            isComplete: false,
            endDate: endDate,
            progress: progress,
            remainingLabel: Self.formatTime(remainingTime)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            lastReportedAlertLevel = currentAlertLevel
        } catch {
            // Live Activity request failed — timer still works without it
        }
    }

    func updateLiveActivity() {
        guard let activity = currentActivity else { return }

        let state = TimerActivityAttributes.ContentState(
            alertLevelRaw: currentAlertLevel.rawValue,
            isPaused: isPaused,
            isComplete: false,
            endDate: endDate,
            progress: progress,
            remainingLabel: Self.formatTime(remainingTime)
        )

        let content = ActivityContent(state: state, staleDate: nil)
        Task { @MainActor in
            await activity.update(content)
        }
    }


    func endLiveActivity(showComplete: Bool) {
        guard let activity = currentActivity else { return }
        currentActivity = nil

        let finalState = TimerActivityAttributes.ContentState(
            alertLevelRaw: AlertLevel.final_.rawValue,
            isPaused: false,
            isComplete: showComplete,
            endDate: Date(),
            progress: 1.0,
            remainingLabel: "0:00"
        )

        let content = ActivityContent(state: finalState, staleDate: nil)
        let dismissDate = Date().addingTimeInterval(30)
        Task { @MainActor in
            if showComplete {
                await activity.update(content)
                await activity.end(content, dismissalPolicy: .after(dismissDate))
            } else {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
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
