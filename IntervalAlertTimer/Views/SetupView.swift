import SwiftUI

struct SetupView: View {
    @Environment(TimerEngine.self) private var engine
    var ringNamespace: Namespace.ID
    @State private var showContent = false
    @State private var appearTime: Date?

    @AppStorage("lastMinutes") private var minutes = 5
    @AppStorage("lastSeconds") private var seconds = 0
    @AppStorage("lastPercentage") private var percentage = 25

    @AppStorage("notificationPermissionRequested") private var permissionRequested = false

    private let notificationService = NotificationService()
    private let percentageOptions = [10, 20, 25, 33, 50]
    private let showQuickChips = false

    var totalDuration: TimeInterval {
        TimeInterval(minutes * 60 + seconds)
    }

    var isValid: Bool {
        totalDuration >= 5
    }

    var config: TimerConfiguration {
        TimerConfiguration(totalDuration: totalDuration, intervalMode: .percentage(percentage))
    }

    var normalizedOffsets: [Double] {
        guard isValid else { return [] }
        return config.alertOffsets.map { $0 / config.totalDuration }
    }

    private var allPresets: [TimerPreset] {
        let custom = loadCustomPresets()
        return TimerPreset.builtInPresets + custom
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // Ring with pickers inside
                ZStack {
                    ProgressRingView(
                        progress: 0,
                        alertLevel: .gentle,
                        alertOffsets: normalizedOffsets
                    )

                    HStack(spacing: 0) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...120, id: \.self) { m in
                                Text("\(m)").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70, height: 120)

                        Text(":")
                            .font(.system(size: 36, weight: .thin, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.bottom, 18)

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0...59, id: \.self) { s in
                                Text(String(format: "%02d", s)).tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70, height: 120)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                .frame(width: 260, height: 260)
                .matchedGeometryEffect(id: "timerRing", in: ringNamespace)
                .padding(.bottom, 28)

                // Below-ring content
                Group {
                // Quick duration chips
                if showQuickChips {
                    HStack(spacing: 8) {
                        QuickChip(label: "1m", m: 1, s: 0)
                        QuickChip(label: "3m", m: 3, s: 0)
                        QuickChip(label: "5m", m: 5, s: 0)
                        QuickChip(label: "10m", m: 10, s: 0)
                        QuickChip(label: "25m", m: 25, s: 0)
                    }
                    .padding(.bottom, 24)
                }

                // Interval section
                Text("Alert Every")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 10)

                HStack(spacing: 8) {
                    ForEach(percentageOptions, id: \.self) { pct in
                        Button {
                            percentage = pct
                        } label: {
                            Text("\(pct)%")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    percentage == pct
                                        ? Theme.accent
                                        : Theme.backgroundRaised
                                )
                                .foregroundStyle(percentage == pct ? Theme.backgroundDeep : Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.bottom, 12)

                // Summary
                if isValid {
                    Text("\(config.alertCount) alerts over \(TimerEngine.formatTime(totalDuration)) · Every \(percentage)%")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.bottom, 32)
                }

                // Start button
                Button {
                    startTimer()
                } label: {
                    Text("Start")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Theme.accent : Theme.accentMuted)
                        .foregroundStyle(isValid ? Theme.backgroundDeep : Theme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom, 36)

                // Presets inline
                VStack(alignment: .leading, spacing: 0) {
                    Text("Presets")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        let presets = allPresets
                        ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                            Button {
                                applyPreset(preset)
                                startTimer()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(preset.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(TimerEngine.formatTime(preset.configuration.totalDuration)) · \(preset.configuration.intervalMode.displayLabel)")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Theme.accent)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 14)
                            }

                            if index < presets.count - 1 {
                                Divider()
                                    .overlay(Theme.backgroundDivider)
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Theme.backgroundSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
                } // end Group
                .opacity(showContent ? 1 : 0)
            }
        }
        .background(Theme.backgroundDeep)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showContent = false
            appearTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showContent = true
                }
            }
        }
    }

    @ViewBuilder
    private func QuickChip(label: String, m: Int, s: Int) -> some View {
        Button {
            minutes = m
            seconds = s
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    minutes == m && seconds == s
                        ? Theme.accent.opacity(0.2)
                        : Theme.backgroundRaised
                )
                .clipShape(Capsule())
        }
    }

    private func startTimer() {
        let timerConfig = TimerConfiguration(totalDuration: totalDuration, intervalMode: .percentage(percentage))

        Task {
            if !permissionRequested {
                _ = await notificationService.requestPermission()
                permissionRequested = true
            }
        }

        engine.start(with: timerConfig)
    }

    private func applyPreset(_ preset: TimerPreset) {
        let c = preset.configuration
        minutes = Int(c.totalDuration) / 60
        seconds = Int(c.totalDuration) % 60
        if case .percentage(let pct) = c.intervalMode {
            percentage = pct
        }
    }

    private func loadCustomPresets() -> [TimerPreset] {
        guard let data = UserDefaults.standard.data(forKey: "savedPresets"),
              let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data)
        else { return [] }
        return decoded
    }
}
