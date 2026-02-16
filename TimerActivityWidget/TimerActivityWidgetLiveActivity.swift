import ActivityKit
import SwiftUI
import WidgetKit

struct TimerActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let level = LiveLevel(context: context)
            let timerRange = timerInterval(context: context)

            return DynamicIsland {
                // MARK: - Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(level.glowColor)
                            .frame(width: 8, height: 8)
                        Text(level.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                        Text("·")
                            .foregroundStyle(.white.opacity(0.25))
                        Text(context.attributes.intervalModeLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                    .padding(.top, 6)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if context.state.isComplete {
                            Text("COMPLETE")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(level.glowColor)
                        } else if context.state.isPaused {
                            Text("PAUSED")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        } else {
                            Text(timerInterval: timerRange, countsDown: true)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isComplete || context.state.isPaused {
                        ProgressView(value: context.state.progress)
                            .tint(level.glowColor)
                            .padding(.horizontal, 4)
                    } else {
                        ProgressView(timerInterval: timerRange, countsDown: false) { EmptyView() }
                            .tint(level.glowColor)
                            .padding(.horizontal, 4)
                    }
                }

            } compactLeading: {
                Circle()
                    .fill(level.glowColor)
                    .frame(width: 8, height: 8)

            } compactTrailing: {
                Text(timerInterval: timerRange, countsDown: true)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 36)
                    .lineLimit(1)

            } minimal: {
                Circle()
                    .fill(level.glowColor)
                    .frame(width: 11, height: 11)
            }
        }
    }

    private func timerInterval(context: ActivityViewContext<TimerActivityAttributes>) -> ClosedRange<Date> {
        let end = context.state.endDate
        let start = end.addingTimeInterval(-context.attributes.totalDuration)
        return start...end
    }
}

// MARK: - Live Alert Level

/// Computes the alert level from endDate + totalDuration at render time.
private struct LiveLevel {
    let glowColor: Color
    let label: String

    init(context: ActivityViewContext<TimerActivityAttributes>) {
        let state = context.state
        let level: AlertLevel
        if state.isPaused || state.isComplete {
            level = AlertLevel(rawValue: state.alertLevelRaw) ?? .gentle
        } else {
            let remaining = max(state.endDate.timeIntervalSinceNow, 0)
            let total = context.attributes.totalDuration
            let progress = total > 0 ? min(max(1.0 - remaining / total, 0), 1.0) : 0
            level = AlertLevel.forProgress(progress)
        }
        self.glowColor = level.glowColor
        self.label = level.label
    }
}

// MARK: - Lock Screen Banner

private struct CompactRing: View {
    var progress: Double
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var level: LiveLevel { LiveLevel(context: context) }

    private var timerRange: ClosedRange<Date> {
        let end = context.state.endDate
        let start = end.addingTimeInterval(-context.attributes.totalDuration)
        return start...end
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(level.glowColor)
                    .frame(width: 8, height: 8)
                    .offset(y: -2)

                if context.state.isComplete {
                    Text("COMPLETE")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(level.glowColor)
                } else if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Text(timerInterval: timerRange, countsDown: true)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.attributes.intervalModeLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    Text(formatDuration(context.attributes.totalDuration))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineLimit(1)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }

            if context.state.isComplete || context.state.isPaused {
                ProgressView(value: context.state.progress)
                    .tint(level.glowColor)
            } else {
                ProgressView(timerInterval: timerRange, countsDown: false) { EmptyView() }
                    .tint(level.glowColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .background(Color(hex: 0x0F1114))
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if s > 0 {
            return "\(m)m \(s)s"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: TimerActivityAttributes(
    totalDuration: 300,
    intervalModeLabel: "Every 25%"
)) {
    TimerActivityWidgetLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        alertLevelRaw: AlertLevel.moderate.rawValue,
        isPaused: false,
        isComplete: false,
        endDate: Date().addingTimeInterval(180),
        progress: 0.4,
        remainingLabel: "3:00"
    )
    TimerActivityAttributes.ContentState(
        alertLevelRaw: AlertLevel.urgent.rawValue,
        isPaused: true,
        isComplete: false,
        endDate: Date().addingTimeInterval(90),
        progress: 0.7,
        remainingLabel: "1:30"
    )
    TimerActivityAttributes.ContentState(
        alertLevelRaw: AlertLevel.final_.rawValue,
        isPaused: false,
        isComplete: true,
        endDate: Date(),
        progress: 1.0,
        remainingLabel: "0:00"
    )
}
