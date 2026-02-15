import SwiftUI

struct TimerRunningView: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Glow effect
            GlowEffectView(
                progress: engine.progress,
                alertLevel: engine.currentAlertLevel,
                isActive: engine.isRunning && !engine.isPaused
            )

            // Main content
            VStack(spacing: 30) {
                Spacer()

                // Alert level label
                Text(engine.currentAlertLevel.label.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(engine.currentAlertLevel.glowColor)

                // Progress ring with time
                ZStack {
                    let normalizedOffsets: [Double] = {
                        guard let config = engine.configuration else { return [] }
                        return config.alertOffsets.map { $0 / config.totalDuration }
                    }()

                    ProgressRingView(
                        progress: engine.progress,
                        alertLevel: engine.currentAlertLevel,
                        alertOffsets: normalizedOffsets
                    )
                    .frame(width: 260, height: 260)

                    // Countdown text
                    VStack(spacing: 4) {
                        Text(TimerEngine.formatTime(engine.remainingTime))
                            .font(.system(size: 56, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text("\(Int(engine.progress * 100))%")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                // Status
                if engine.isComplete {
                    Text("Complete!")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.green)
                } else if engine.isPaused {
                    Text("Paused")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Controls
                HStack(spacing: 40) {
                    if engine.isComplete {
                        Button {
                            engine.cancel()
                        } label: {
                            ControlButton(icon: "checkmark", label: "Done", color: .green)
                        }
                    } else {
                        // Cancel
                        Button {
                            engine.cancel()
                        } label: {
                            ControlButton(icon: "xmark", label: "Cancel", color: .red)
                        }

                        // Pause/Resume
                        Button {
                            if engine.isPaused {
                                engine.resume()
                            } else {
                                engine.pause()
                            }
                        } label: {
                            ControlButton(
                                icon: engine.isPaused ? "play.fill" : "pause.fill",
                                label: engine.isPaused ? "Resume" : "Pause",
                                color: .accentColor
                            )
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func ControlButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(Circle())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
