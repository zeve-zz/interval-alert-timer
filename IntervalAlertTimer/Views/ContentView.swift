import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        NavigationStack {
            if engine.isRunning || engine.isComplete {
                TimerRunningView()
            } else {
                SetupView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
