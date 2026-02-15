import SwiftUI

struct SetupView: View {
    @Environment(TimerEngine.self) private var engine

    @AppStorage("lastMinutes") private var minutes = 5
    @AppStorage("lastSeconds") private var seconds = 0
    @AppStorage("lastUsePercentage") private var usePercentage = true
    @AppStorage("lastPercentage") private var percentage = 25
    @AppStorage("lastFixedMinutes") private var fixedMinutes = 1
    @AppStorage("lastFixedSeconds") private var fixedSeconds = 0
    @State private var showPresets = false

    @AppStorage("notificationPermissionRequested") private var permissionRequested = false

    private let notificationService = NotificationService()

    var totalDuration: TimeInterval {
        TimeInterval(minutes * 60 + seconds)
    }

    var intervalMode: IntervalMode {
        if usePercentage {
            return .percentage(percentage)
        } else {
            return .fixedTime(TimeInterval(fixedMinutes * 60 + fixedSeconds))
        }
    }

    var isValid: Bool {
        totalDuration >= 5
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Title
                Text("Interval Timer")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 20)

                // Duration Section
                VStack(spacing: 8) {
                    Label("Duration", systemImage: "timer")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DurationPicker(minutes: $minutes, seconds: $seconds)

                    // Quick presets
                    HStack(spacing: 10) {
                        QuickPresetButton(label: "1 min", minutes: 1, seconds: 0)
                        QuickPresetButton(label: "3 min", minutes: 3, seconds: 0)
                        QuickPresetButton(label: "5 min", minutes: 5, seconds: 0)
                        QuickPresetButton(label: "10 min", minutes: 10, seconds: 0)
                        QuickPresetButton(label: "25 min", minutes: 25, seconds: 0)
                    }
                }
                .padding(.horizontal)

                // Interval Section
                VStack(spacing: 8) {
                    Label("Alert Interval", systemImage: "bell.badge")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    IntervalModePicker(
                        usePercentage: $usePercentage,
                        percentage: $percentage,
                        fixedMinutes: $fixedMinutes,
                        fixedSeconds: $fixedSeconds
                    )
                }
                .padding(.horizontal)

                // Summary
                if isValid {
                    let config = TimerConfiguration(totalDuration: totalDuration, intervalMode: intervalMode)
                    VStack(spacing: 4) {
                        Text("\(config.alertCount) alerts over \(TimerEngine.formatTime(totalDuration))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(intervalMode.displayLabel)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Start Button
                Button {
                    startTimer()
                } label: {
                    Text("Start Timer")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.accentColor : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isValid)
                .padding(.horizontal)

                // Presets button
                Button {
                    showPresets = true
                } label: {
                    Label("Saved Presets", systemImage: "bookmark")
                        .font(.subheadline)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showPresets) {
            PresetsView { preset in
                applyPreset(preset)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func QuickPresetButton(label: String, minutes m: Int, seconds s: Int) -> some View {
        Button {
            minutes = m
            seconds = s
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    self.minutes == m && self.seconds == s
                        ? Color.accentColor.opacity(0.2)
                        : Color(.systemGray5)
                )
                .clipShape(Capsule())
        }
    }

    private func startTimer() {
        let config = TimerConfiguration(totalDuration: totalDuration, intervalMode: intervalMode)

        Task {
            if !permissionRequested {
                _ = await notificationService.requestPermission()
                permissionRequested = true
            }
        }

        engine.start(with: config)
    }

    private func applyPreset(_ preset: TimerPreset) {
        let config = preset.configuration
        minutes = Int(config.totalDuration) / 60
        seconds = Int(config.totalDuration) % 60
        switch config.intervalMode {
        case .percentage(let pct):
            usePercentage = true
            percentage = pct
        case .fixedTime(let interval):
            usePercentage = false
            fixedMinutes = Int(interval) / 60
            fixedSeconds = Int(interval) % 60
        }
    }
}
