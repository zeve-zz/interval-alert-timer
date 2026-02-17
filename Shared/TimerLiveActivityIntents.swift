import AppIntents
import ActivityKit

struct TogglePauseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Toggle Pause"

    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        await MainActor.run {
            guard let engine = TimerEngine.shared else { return }
            if engine.isPaused {
                engine.resume()
            } else {
                engine.pause()
            }
        }
        #endif
        return .result()
    }
}

struct CancelTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Cancel Timer"

    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        await MainActor.run {
            TimerEngine.shared?.cancel()
        }
        #endif
        return .result()
    }
}
