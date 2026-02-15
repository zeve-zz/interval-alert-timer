import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine
    @Namespace private var ringNamespace

    var body: some View {
        NavigationStack {
            ZStack {
                if engine.isRunning || engine.isComplete {
                    TimerRunningView(ringNamespace: ringNamespace)
                        .transition(.opacity)
                } else {
                    SetupView(ringNamespace: ringNamespace)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: engine.isRunning)
        }
        .preferredColorScheme(.dark)
    }
}
