import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var alertLevel: AlertLevel
    var alertOffsets: [Double] // normalized 0-1

    private let lineWidth: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2

            ZStack {
                Circle()
                    .stroke(Theme.ringTrack, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        alertLevel.glowColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                ForEach(Array(alertOffsets.enumerated()), id: \.offset) { _, normalizedOffset in
                    if normalizedOffset < 1.0 {
                        MarkerDot(
                            passed: normalizedOffset <= progress,
                            color: alertLevel.glowColor,
                            radius: radius,
                            angle: normalizedOffset * 360
                        )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct MarkerDot: View {
    var passed: Bool
    var color: Color
    var radius: CGFloat
    var angle: Double

    @State private var glowAmount: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer diffused glow
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .blur(radius: 14)
                .opacity(glowAmount * 0.7)
                .scaleEffect(0.8 + glowAmount * 0.4)

            // Inner tighter glow
            Circle()
                .fill(color)
                .frame(width: 18, height: 18)
                .blur(radius: 6)
                .opacity(glowAmount * 0.9)
                .scaleEffect(0.8 + glowAmount * 0.3)

            // Core dot
            Circle()
                .fill(passed ? color : Color(.systemGray3))
                .frame(width: 10, height: 10)
        }
        .offset(y: -radius)
        .rotationEffect(.degrees(angle))
        .onChange(of: passed) { _, isPassed in
            guard isPassed else { return }
            // Single animatable value drives everything
            glowAmount = 0
            withAnimation(.easeOut(duration: 0.8)) {
                glowAmount = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    glowAmount = 0
                }
            }
        }
    }
}
