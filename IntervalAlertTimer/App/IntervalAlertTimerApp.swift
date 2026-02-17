import SwiftUI

@main
struct IntervalAlertTimerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var engine = TimerEngine()
    private let hapticService = HapticService()
    private let audioService = AudioService()
    private let notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .onAppear {
                    TimerEngine.shared = engine
                    engine.restoreIfNeeded()
                    audioService.configureAudioSession()
                    engine.onAlertFired = { _, index in
                        let count = index + 1
                        hapticService.fire(count: count)
                        audioService.fire(count: count)
                    }
                    engine.onResumed = { [notificationService] in
                        if let config = engine.configuration {
                            notificationService.scheduleAlerts(for: config, startDate: Date(), elapsed: engine.elapsed)
                        }
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhase(from: oldPhase, to: newPhase)
                }
        }
    }

    private func handleScenePhase(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // If the engine isn't running, try to restore from a previous session (app was killed)
            if !engine.isRunning && !engine.isComplete {
                engine.restoreIfNeeded()
            }
            // Returning to foreground — recalculate from Date, cancel remaining notifications
            if engine.isRunning {
                notificationService.cancelAll()
                engine.recalculateFromDate()
            }
            // Immediately sync Live Activity with actual state
            if engine.isRunning || engine.isComplete {
                engine.updateLiveActivity()
            }
        case .background:
            // Persist timer state so it survives app kill
            engine.saveState()
            // Going to background — schedule notifications for remaining alerts
            if engine.isRunning, !engine.isPaused, let config = engine.configuration {
                let el = engine.elapsed
                notificationService.scheduleAlerts(for: config, startDate: Date(), elapsed: el)
            }
            // Refresh Live Activity so countdown stays accurate on lock screen
            if engine.isRunning {
                engine.updateLiveActivity()
            }
        default:
            break
        }
    }
}
