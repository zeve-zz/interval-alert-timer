import SwiftUI

struct GlowEffectView: View {
    var progress: Double
    var alertLevel: AlertLevel
    var isActive: Bool

    @State private var animateGlow = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Multiple layered glow rectangles for a diffused edge effect
                ForEach(0..<3, id: \.self) { layer in
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(alertLevel.glowColor, lineWidth: CGFloat(20 - layer * 5))
                        .blur(radius: CGFloat(30 + layer * 15))
                        .opacity(animateGlow ? (0.6 - Double(layer) * 0.15) : 0.15)
                        .padding(CGFloat(layer * -10))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: alertLevel) { _, _ in
            restartAnimation()
        }
        .onChange(of: isActive) { _, active in
            if active { restartAnimation() } else { animateGlow = false }
        }
        .onAppear {
            if isActive { restartAnimation() }
        }
    }

    private func restartAnimation() {
        animateGlow = false
        withAnimation(
            .easeInOut(duration: alertLevel.pulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            animateGlow = true
        }
    }
}
