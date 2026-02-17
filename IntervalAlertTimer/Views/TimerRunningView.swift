import SwiftUI

struct TimerRunningView: View {
    @Environment(TimerEngine.self) private var engine
    @State private var flipAngle: Double = 0
    @State private var displayedLabel: String = ""
    @State private var pauseGlow: CGFloat = 0
    var ringNamespace: Namespace.ID

    var statusLabel: String {
        if engine.isDismissing { return "" }
        if engine.isComplete { return "COMPLETE" }
        if engine.isPaused { return "PAUSED" }
        return engine.currentAlertLevel.label.uppercased()
    }

    var statusColor: Color {
        if engine.isComplete { return Color(hex: 0x8AABA0) }
        if engine.isPaused { return Theme.textSecondary }
        return engine.currentAlertLevel.glowColor
    }

    var body: some View {
        ZStack {
            // Background
            Theme.backgroundDeep.ignoresSafeArea()

            // Glow effect
            GlowEffectView(
                progress: engine.progress,
                alertLevel: engine.currentAlertLevel,
                isActive: engine.isRunning && !engine.isPaused && !engine.isDismissing
            )
            .opacity(engine.isDismissing ? 0 : 1)

            // Main content
            VStack(spacing: 30) {
                Spacer()

                // Status label (shows alert level, "Paused", or "Complete")
                Text(displayedLabel)
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(statusColor)
                    .shadow(color: Theme.accent.opacity(pauseGlow), radius: 12)
                    .shadow(color: Theme.accent.opacity(pauseGlow * 0.5), radius: 24)
                    .opacity(engine.isDismissing ? 0 : 1.0)
                    .rotation3DEffect(.degrees(flipAngle), axis: (x: 1, y: 0, z: 0))
                    .onChange(of: statusLabel) { oldVal, newVal in
                        if newVal.isEmpty { return }
                        guard oldVal != newVal else { return }
                        withAnimation(.easeIn(duration: 0.15)) {
                            flipAngle = 90
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            displayedLabel = newVal
                            flipAngle = -90
                            withAnimation(.easeOut(duration: 0.15)) {
                                flipAngle = 0
                            }
                        }
                    }
                    .onAppear {
                        displayedLabel = statusLabel
                    }
                    .onChange(of: displayedLabel) { _, newVal in
                        if newVal == "PAUSED" {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pauseGlow = 1.0
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.3)) {
                                pauseGlow = 0
                            }
                        }
                    }

                // Progress ring with time
                ZStack {
                    let normalizedOffsets: [Double] = {
                        guard let config = engine.configuration else { return [] }
                        return config.alertOffsets.map { $0 / config.totalDuration }
                    }()

                    ProgressRingView(
                        progress: engine.progress,
                        alertLevel: engine.currentAlertLevel,
                        alertOffsets: normalizedOffsets,
                        isDismissing: engine.isDismissing
                    )
                    .frame(width: 260, height: 260)

                    // Countdown text
                    VStack(spacing: 4) {
                        Text(TimerEngine.formatTime(engine.remainingTime))
                            .font(.system(size: 56, weight: .thin, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text("\(Int(engine.progress * 100))%")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(engine.isDismissing ? 0 : 1)
                }
                .matchedGeometryEffect(id: "timerRing", in: ringNamespace)

                // Spacer instead of status text area — keeps layout stable
                Spacer().frame(height: 30)

                Spacer()

                // Controls
                HStack(spacing: 40) {
                    if engine.isComplete {
                        Button {
                            engine.dismiss()
                        } label: {
                            ControlButton(icon: "checkmark", label: "Done", color: Theme.accent)
                        }
                    } else {
                        // Cancel
                        Button {
                            engine.dismiss()
                        } label: {
                            ControlButton(icon: "xmark", label: "Cancel", color: Theme.destructive)
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
                                color: Theme.accent
                            )
                        }
                    }
                }
                .opacity(engine.isDismissing ? 0 : 1)
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden()
        .animation(.easeInOut(duration: 0.5), value: engine.isDismissing)
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
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
